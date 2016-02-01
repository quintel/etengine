module Qernel::Plugins
  module Merit
    # An adapter which deals with flexible and storage technologies in the merit
    # order. These technologies store excess for future use, or remove excess
    # via export or curtailment.
    class FlexAdapter < Adapter
      def self.factory(converter, graph, dataset)
        case converter.dataset_get(:merit_order).group.to_sym
          when :power_to_power, :power_to_heat, :electric_vehicle
            StorageAdapter
          else
            self
        end
      end

      def inject!
        full_load_hours = participant.full_load_hours

        if ! full_load_hours || full_load_hours.nan?
          full_load_seconds = full_load_hours = 0.0
        else
          full_load_seconds = full_load_hours * 3600
        end

        @converter[:full_load_hours]   = full_load_hours
        @converter[:full_load_seconds] = full_load_seconds

        @converter.demand =
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

        # TODO Temporary; some flex techs have a hard-coded availability of 0.0
        #      which results in them never running.
        attrs[:availability] = 1.0

        attrs
      end

      def producer_class
        if @config.group == :power_to_gas || @config.group == :export
          ::Merit::Flex::BlackHole
        else
          ::Merit::Flex::Base
        end
      end
    end # FlexAdapter
  end # Merit
end
