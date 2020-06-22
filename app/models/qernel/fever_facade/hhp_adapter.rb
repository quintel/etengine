# frozen_string_literal: true

module Qernel
  module FeverFacade
    # An adapter which sets up a hybrid heat-pump to participate in Fever.
    #
    # Hybrid heat-pumps comprise two separate components: a primary and
    # secondary component. The primary is a VariableEfficiencyProducer which
    # balances two input carriers based on the efficiency of the producer. For
    # example, a node with:
    #
    #   - fever.efficiency_based_on = electricity
    #   - fever.efficiency_balanced_with = ambient_heat
    #
    # Configures the primary component to use electricity and ambient heat. With
    # a fixed coefficient-of-performance of 3, the producer will use two units
    # of ambient heat for every one unit of electricity, outputting three units
    # of heat.
    #
    # The third (unnamed) input carrier to the node is used as the input carrier
    # for the secondary component.
    #
    # The secondary component may also have an output efficiency defined the
    # normal way in the node document:
    #
    #   - output.heat.hydrogen = 1.06
    #
    # For every one unit of hydrogen input to the component, 1.06 units of heat
    # will be output. For this component there is no "balanced_with" carrier:
    # the extra energy simply appears on the node after the calculation.
    #
    # Since the efficiencies and shares of carriers may change by the Fever
    # calculation, it is not possible to set an output conversion on the node
    # other than 1.0. If half of the input energy for the node were to come from
    # the primary component, and half from the secondary, setting an output
    # conversion of 1.03 would result in inaccurate input of the primary
    # component carriers. To that end, the node will be hard-coded to an
    # output conversion of 1.0, and the input shares will be adjusted to ensure
    # the flow of energ into the node is correct.
    class HHPAdapter < ProducerAdapter
      MJ_IN_MWH = 3600

      def inject!
        if @number_of_units.zero? ||
            participant.producer.output_curve.all?(&:zero?)
          return
        end

        # Sets the load-adjusted efficiency of the primary component carriers.
        # primary_adapter.inject!

        @node.node.output(:useable_heat)[:conversion] = 1.0

        # Set the demands and other attributes based on the whole producer and
        # not the individual parts.
        super

        set_input_conversions!
      end

      def producer
        Fever::CompositeProducer.new([primary_component, secondary_component])
      end

      def producer_for_carrier(carrier)
        case carrier
        when @config.efficiency_based_on then primary_component
        when secondary_carrier           then secondary_component
        end
      end

      # Public: Returns if the named carrier (a Symbol) is one of the inputs to
      # the node used by this adapter.
      #
      # Returns true or false.
      def input?(carrier)
        [@config.efficiency_based_on, secondary_carrier].include?(carrier)
      end

      private

      # Internal: The Fever producer which will be the first one asked to
      # satisfy demand.
      def primary_component
        @primary_component ||= primary_adapter.participant.producer
      end

      # Internal: The Fever producer which will be used when the primary
      # producer cannot meet demand.
      def secondary_component
        @secondary_component ||=
          Fever::Producer.new(
            if @config.alias_of
              DelegatedCapacityCurve.new(
                total_value { @config.capacity[secondary_carrier] },
                aliased_adapter.producer_for_carrier(secondary_carrier)
              )
            else
              total_value { @config.capacity[secondary_carrier] }
            end,
            input_efficiency: output_efficiency_of_carrier(secondary_carrier)
          )
      end

      # Internal: The primary producer is typically a variable-efficiency heat
      # pump.
      def primary_adapter
        @primary_adapter ||= VariableEfficiencyProducerAdapter.new(
          @node.node, @context
        )
      end

      # Internal: The share of the secondary component carrier.
      def secondary_share
        @node.node.input(secondary_carrier).conversion
      end

      # Internal: Symbol naming the input carrier used by the secondary
      # component.
      #
      # Returns a Symbol, or raises an error if there is not suitable - or more
      # than one - carrier.
      def secondary_carrier
        return @secondary_carrier if @secondary_carrier

        carriers = @node.node.inputs.map { |i| i.carrier.key } -
          [@config.efficiency_based_on, @config.efficiency_balanced_with]

        if carriers.length.zero?
          raise 'No secondary carrier available for hybrid heat-pump ' \
                "#{@node.key}. Are you sure this is a HHP?"
        elsif carriers.length != 1
          raise "Too many carriers for hybrid heat-pump #{@node.key}. " \
                "Expected only one of: #{carriers.join(', ')}"
        end

        @secondary_carrier = carriers.first
      end

      # Internal: Sets the input conversions after the calculation to match the
      # use of energy by the Fever components.
      def set_input_conversions!
        return if @node.demand.zero?

        primary_demand = primary_component.input_curve.sum
        based_on_input = source_energy_of_component(primary_component)
        balanced_with_input = primary_demand - based_on_input

        sec_eff = output_efficiency_of_carrier(secondary_carrier)
        secondary_input = secondary_component.input_curve.sum / sec_eff

        @node.node.input(:electricity)[:conversion] =
          (based_on_input * MJ_IN_MWH) / @node.demand

        @node.node.input(:ambient_heat)[:conversion] =
          (balanced_with_input * MJ_IN_MWH) / @node.demand

        @node.node.input(secondary_carrier)[:conversion] =
          (secondary_input * MJ_IN_MWH) / @node.demand
      end

      # Internal: Calculates the total amount of "source" input to the given
      # component.
      def source_energy_of_component(component)
        energy = 0.0

        component.input_curve.length.times do |frame|
          energy += component.source_at(frame)
        end

        energy
      end

      # Internal: Returns the output efficiency defined in the Node document, if
      # present, otherwise returns 1.0.
      #
      # Some nodes will define different output efficiencies depending on which
      # carrier is used to create the heat output:
      #
      #   - output.heat.electricity = 1.1
      #   - output.heat.hydrogen = 1.06
      #
      # Given the carrier name, the appropriate efficiency is returned:
      #
      #   output_efficiency_of_carrier(:electricity) # => 1.1
      #   output_efficiency_of_carrier(:hydrogen)    # => 1.06
      #   output_efficiency_of_carrier(:network_gas) # => 1.0
      #
      # Returns a numeric.
      def output_efficiency_of_carrier(carrier)
        output = Atlas::Node.find(@node.key).output[:useable_heat]
        output.is_a?(Hash) ? output[carrier] : 1.0
      end

      def output_efficiency
        1.0
      end

      def inject_input_curves!
        primary_carrier = @config.efficiency_based_on

        inject_curve!(full_name: "#{primary_carrier}_input_curve") do
          Array.new(8760, &demand_callable_for_carrier(primary_carrier))
        end

        inject_curve!(full_name: "#{secondary_carrier}_input_curve") do
          Array.new(8760, &demand_callable_for_carrier(secondary_carrier))
        end
      end
    end
  end
end
