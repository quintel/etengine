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
        if converter.dataset_get(:fever).efficiency_based_on
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
        producer = participant.producer
        heat_production = producer.load_curve.sum * 3600 # MWh -> MJ

        if heat_production.zero?
          full_load_hours = 0.0
        else
          full_load_hours = heat_production / producer.capacity
        end

        @converter.demand              = heat_production / output_efficiency
        @converter[:full_load_hours]   = full_load_hours
        @converter[:full_load_seconds] = full_load_hours * 3600
      end

      private

      def output_efficiency
        slots = @converter.converter.outputs.reject(&:loss?)
        slots.any? ? slots.sum(&:conversion) : 1.0
      end

      def input_efficiency
        slots = @converter.converter.inputs.reject(&:loss?)
        slots.any? ? slots.sum(&:conversion) : 1.0
      end

      def producer
        if (st = @converter.dataset_get(:storage)) && st.volume > 0
          ::Fever::BufferingProducer.new(
            total_value(:heat_output_capacity), reserve,
            input_efficiency: input_efficiency
          )
        else
          ::Fever::Producer.new(
            total_value(:heat_output_capacity),
            input_efficiency: input_efficiency
          )
        end
      end

      def reserve
        ::Merit::Flex::Reserve.new(
          total_value { @converter.dataset_get(:storage).volume }
        )
      end

      def share
        @converter.converter.output(:useable_heat).links.first.share
      end
    end # ProducerAdapter
  end
end
