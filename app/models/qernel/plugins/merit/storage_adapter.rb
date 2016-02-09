module Qernel::Plugins
  module Merit
    class StorageAdapter < FlexAdapter
      private

      def producer_attributes
        attrs = super

        attrs[:input_capacity_per_unit] =
          @converter.input_capacity ||
          @converter.output_capacity

        attrs[:volume_per_unit] =
          @converter.dataset_get(:storage).volume *
          (1 - (@converter.reserved_fraction || 0.0))

        attrs[:input_efficiency]  = input_efficiency
        attrs[:output_efficiency] = output_efficiency

        attrs
      end

      def producer_class
        ::Merit::Flex::Storage
      end

      def input_efficiency
        slots = target_api.converter.inputs.reject(&:loss?)
        1 / (slots.any? ? slots.sum(&:conversion) : 1.0)
      end
    end # StorageAdapter
  end # Merit
end
