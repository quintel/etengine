module Qernel::Plugins
  module Fever
    # Represents a Fever participant which will provide energy needed to meet
    # demand.
    class ProducerAdapter < Adapter
      def participant
        @participant ||=
          ::Fever::Activity.new(
            ::Fever::Producer.new(total_value(:heat_output_capacity) / 100),
            share: @converter.converter.output(:useable_heat).links.first.share
          )
      end

      def inject!
        heat_production = participant.producer.load_curve.sum * 3600 # MWh -> MJ
        full_load_hours = heat_production / total_value(:heat_output_capacity)

        @converter.demand              = heat_production / output_efficiency
        @converter[:full_load_hours]   = full_load_hours
        @converter[:full_load_seconds] = full_load_hours * 3600
      end

      private

      def output_efficiency
        slots = @converter.converter.outputs.reject(&:loss?)
        slots.any? ? slots.sum(&:conversion) : 1.0
      end
    end # ProducerAdapter
  end
end
