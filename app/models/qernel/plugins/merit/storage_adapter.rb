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
          (@converter.dataset_get(:storage).volume / 1_000_000) * # Wh to Mwh
          (1 - (@converter.reserved_fraction || 0.0))

        attrs
      end

      def producer_class
        ::Merit::Flex::Storage
      end
    end # StorageAdapter
  end # Merit
end
