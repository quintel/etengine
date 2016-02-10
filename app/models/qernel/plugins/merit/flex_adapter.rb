module Qernel::Plugins
  module Merit
    # An adapter which deals with flexible and storage technologies in the merit
    # order. These technologies store excess for future use, or remove excess
    # via export or curtailment.
    class FlexAdapter < Adapter
      def self.factory(converter, graph, dataset)
        case converter.dataset_get(:merit_order).group.to_sym
          when :power_to_power, :electric_vehicle
            StorageAdapter
          when :power_to_heat
            PowerToHeatAdapter
          when :curtailment, :export
            CurtailmentAdapter
          else
            self
        end
      end

      def inject!
        target          = target_api
        full_load_hours = participant.full_load_hours * output_efficiency

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        target[:full_load_hours]   = full_load_hours
        target[:full_load_seconds] = full_load_seconds

        target.demand =
          full_load_seconds *
          @converter.input_capacity *
          participant.number_of_units
      end

      private

      def producer_attributes
        attrs = super

        # Default is to multiply the input capacity by the electricity output
        # conversion. This doesn't work, because the flex converters have a
        # dependant electricity link and the conversion will be zero the first
        # time the graph is calculated.
        attrs[:output_capacity_per_unit] =
          @converter.output_capacity ||
          @converter.input_capacity

        attrs
      end

      def output_efficiency
        slots = target_api.converter.outputs.reject(&:loss?)
        slots.any? ? slots.sum(&:conversion) : 1.0
      end

      def producer_class
        ::Merit::Flex::Base
      end

      # Internal: The converter on which to set a demand.
      #
      # Some flexible converter set their demands on a different converter (EV
      # sets a demand on the separate EV P2P converter, instead of itself). This
      # method returns the converter on which to set the demand.
      #
      # Returns a Qernel::ConverterApi.
      def target_api
        if @config.target.present?
          @graph.converter(@config.target).converter_api
        else
          @converter
        end
      end
    end # FlexAdapter
  end # Merit
end
