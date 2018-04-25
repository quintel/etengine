module Qernel::Plugins
  module Fever
    # Represents a Fever participant which will store excess energy from
    # elsewhere, convert it to heat, and make it available for use later.
    class StorageAdapter < ProducerAdapter
      # Prevents the demand of the producer being included twice in the Merit
      # order: once as P2H and again in the Fever hot water curve.
      def producer_for_electricity_demand
        nil
      end

      def participant
        @participant ||=
          ::Fever::Activity.new(
            ::Fever::ReserveProducer.new(
              total_value(:heat_output_capacity),
              reserve
            )
          )
      end

      private

      def reserve
        ::Merit::Flex::Reserve.new(
          total_value { @converter.dataset_get(:storage).volume }
        )
      end
    end # StorageAdapter
  end
end
