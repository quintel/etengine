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

        full_load_hours =
          if production.zero?
            0.0
          else
            production / total_value(:heat_output_capacity)
          end

        @converter.demand = (production * 3600) / output_efficiency # MWh -> MJ

        @converter[:full_load_hours]   = full_load_hours
        @converter[:full_load_seconds] = full_load_hours * 3600

        if @converter.converter.groups.include?(:aggregator_producer)
          demand = participant.demand
          link   = @converter.converter.output(:useable_heat).links.first

          link.share = demand > 0 ? production / demand : 1.0
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
        participant.producer if @converter.converter.input(carrier)
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
        reserve = ::Merit::Flex::Reserve.new(volume)

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
