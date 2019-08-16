module Qernel::Plugins
  module Merit
    class StorageAdapter < FlexAdapter
      def installed?
        # Skip storage when there is no volume for storing energy.
        super && storage_volume_per_unit.positive?
      end

      private

      def producer_attributes
        attrs = super

        attrs[:reserve_class] = ::Merit::Flex::SimpleReserve

        attrs[:input_capacity_per_unit] =
          source_api.input_capacity ||
          source_api.output_capacity

        attrs[:volume_per_unit] = storage_volume_per_unit

        attrs[:input_efficiency]  = input_efficiency
        attrs[:output_efficiency] = output_efficiency

        attrs
      end

      def storage_volume_per_unit
        source_api.dataset_get(:storage).volume *
          (1 - (source_api.reserved_fraction || 0.0))
      end

      def producer_class
        ::Merit::Flex::Storage
      end

      def input_efficiency
        slots = @converter.converter.inputs.reject(&:loss?)
        1 / (slots.any? ? slots.sum(&:conversion) : 1.0)
      end
    end # StorageAdapter
  end # Merit
end
