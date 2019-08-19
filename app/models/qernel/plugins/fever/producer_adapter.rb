# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    # Represents a Fever participant which will provide energy needed to meet
    # demand.
    class ProducerAdapter < Adapter
      # Public: Returns an appropriate adapter class to represent the given
      # converter in Fever.
      #
      # Returns an Adapter class.
      def self.factory(converter, _graph, _dataset)
        if converter.key.to_s.include?('hybrid')
          HHPAdapter
        elsif converter.dataset_get(:fever).efficiency_based_on
          VariableEfficiencyProducerAdapter
        else
          self
        end
      end

      def participant
        @participant ||=
          if @config.defer_for && @config.defer_for > 0
            ::Fever::DeferrableActivity.new(
              producer, share: share, expire_after: @config.defer_for
            )
          else
            ::Fever::Activity.new(producer, share: share)
          end
      end

      def inject!
        producer   = participant.producer
        production = producer.output_curve.sum

        @converter.demand = (production * 3600) / output_efficiency # MWh -> MJ

        if production.positive?
          full_load_hours = production / total_value(:heat_output_capacity)

          @converter[:full_load_hours]   = full_load_hours
          @converter[:full_load_seconds] = full_load_hours * 3600
        end

        if @converter.converter.groups.include?(:aggregator_producer)
          demand = participant.demand
          link   = @converter.converter.output(:useable_heat).links.first

          link.share = demand > 0 ? production / demand : 1.0
        end

        @converter.dataset_lazy_set(:heat_output_curve) do
          producer.output_curve.to_a
        end
      end

      def producer
        if (st = @converter.dataset_get(:storage)) && st.volume > 0
          ::Fever::BufferingProducer.new(
            capacity, reserve,
            input_efficiency: input_efficiency
          )
        else
          ::Fever::Producer.new(capacity, input_efficiency: input_efficiency)
        end
      end

      def producer_for_carrier(carrier)
        participant.producer if input?(carrier)
      end

      # Public: Returns if the named carrier (a Symbol) is one of the inputs to
      # the converter used by this adapter.
      #
      # Returns true or false.
      def input?(carrier)
        !@converter.converter.input(carrier).nil?
      end

      # Public: Creates a callable which takes a frame number and returns how
      # much demand there is for a given carrier in that frame. Accounts for
      # output losses.
      #
      # Returns a proc.
      def demand_callable_for_carrier(carrier)
        if (producer = producer_for_carrier(carrier))
          efficiency = output_efficiency
          ->(frame) { producer.source_at(frame) / efficiency }
        else
          ->(*) { 0.0 }
        end
      end

      # Public: Returns if this adapter has any units installed.
      def installed?
        @converter.number_of_units.positive?
      end

      private

      def output_efficiency
        slots = @converter.converter.outputs.reject(&:loss?)
        slots.any? ? slots.sum(&:conversion) : 1.0
      end

      def input_efficiency
        slots = @converter.converter.inputs.reject do |slot|
          slot.carrier.key == :ambient_heat
        end

        slots.any? ? 1.0 / slots.sum(&:conversion) : 1.0
      end

      # Internal: The total capacity of the Fever participant in each frame.
      #
      # Returns an arrayish.
      def capacity
        return total_value(:heat_output_capacity) unless @config.alias_of

        DelegatedCapacityCurve.new(
          total_value(:heat_output_capacity),
          aliased_adapter.participant.producer,
          input_efficiency
        )
      end

      # Internal: The Fever participant is an alias of a producer in another
      # group; fetch it!
      def aliased_adapter
        alias_group = @graph.plugin(:time_resolve).fever.group(
          @graph.converter(@config.alias_of).dataset_get(:fever).group
        )

        alias_group.adapters
          .detect { |adapter| adapter.converter.key == @config.alias_of }
      end

      def reserve
        volume  = total_value { @converter.dataset_get(:storage).volume }
        reserve = ::Merit::Flex::SimpleReserve.new(volume)

        # Buffer starts full.
        reserve.add(0, volume)

        reserve
      end

      def share
        link = @converter.converter.output(:useable_heat).links.first

        if link.lft_converter.key.to_s.include?('aggregator')
          link.lft_converter.output(:useable_heat).links.first.share
        else
          link.share
        end
      end
    end # ProducerAdapter
  end
end
