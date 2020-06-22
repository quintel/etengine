# frozen_string_literal: true

module Qernel
  module FeverFacade
    # A producer whose efficiency varies throughout the year depending on the
    # ambient temperature.
    class VariableEfficiencyProducerAdapter < ProducerAdapter
      def inject!
        share = combined_share

        super

        load_efficiency = load_adjusted_input_efficiency

        return if load_efficiency.zero?

        efficiency = 1 / load_efficiency

        based_on_slot[:conversion]      = efficiency * share
        balanced_with_slot[:conversion] = (1.0 - efficiency) * share
      end

      # Internal: Computes the actual efficiency of the heat pump over the year,
      # depending on when demand arose.
      #
      # Returns a numeric.
      def load_adjusted_input_efficiency
        producer = participant.producer

        efficiency = input_efficiency

        sum_input = 0.0
        sum_eff   = 0.0

        Fever::FRAMES.times do |index|
          input = producer.source_at(index)

          sum_input += input
          sum_eff   += input * efficiency[index]
        end

        sum_input.zero? ? 0.0 : sum_eff / sum_input
      end

      # Internal: The slot whose efficiency varies depending on the temperature
      # curve.
      def based_on_slot
        @node.node.input(@config.efficiency_based_on)
      end

      # Internal: The slot whose conversion will be adjusted according to the
      # change in efficiency of the "based_on" slot.
      def balanced_with_slot
        @node.node.input(@config.efficiency_balanced_with)
      end

      private

      # Internal: The share of the two inputs.
      def combined_share
        based_on_slot.conversion + balanced_with_slot.conversion
      end

      # Internal: The input efficiency curve to be used by the producer.
      #
      # Returns an array.
      def input_efficiency
        @input_efficiency ||=
          begin
            base_cop   = @config.base_cop
            per_degree = @config.cop_per_degree

            temperature_curve.map do |val|
              cop = base_cop + per_degree * val

              # Coefficient of performance must not drop below 1.0 (where there
              # is no "balanced_with" energy, and only "based_on" energy is
              # used).
              cop < 1.0 ? 1.0 : cop
            end
          end
      end

      # Internal: The curve of air temperatures in the region.
      def temperature_curve
        @context.curves.curve('weather/air_temperature', @node)
      end

      def capacity
        capacity =
          if @config.capacity.present?
            efficiency_based_capacity
          else
            heat_capacity = total_value(:heat_output_capacity)
            node = @node.node

            heat_capacity *= combined_share if node.inputs.length > 2
            heat_capacity
          end

        if @config.alias_of
          DelegatedCapacityCurve.new(
            capacity,
            aliased_adapter.producer_for_carrier(@config.efficiency_based_on),
            input_efficiency
          )
        else
          capacity
        end
      end

      # Internal: Producers with a "capacity" attribute assigned to the producer
      # have a fixed input capacity, and the output capacity is a function of
      # the input and the efficiency.
      #
      # Returns an array.
      def efficiency_based_capacity
        cop_cutoff = @config.cop_cutoff || 1.0

        input_cap =
          total_value do
            @config.capacity[@config.efficiency_based_on]
          end

        input_efficiency.map do |eff|
          eff < cop_cutoff ? 0.0 : input_cap * eff
        end
      end
    end
  end
end
