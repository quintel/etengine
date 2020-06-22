# frozen_string_literal: true

module Qernel
  module FeverFacade
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
          Fever::Activity.new(
            Fever::ReserveProducer.new(
              total_value(:heat_output_capacity),
              reserve
            )
          )
      end

      def inject!
        super

        inject_curve!(:input) { participant.producer.inptu_curve }
      end

      def input?(*)
        # Storage adapters are a "dump" in which excess electricity is converted
        # to heat. Their heat demand is _not_ to be accounted for in Merit
        # otherwise their electricity consumption will be included twice.
        false
      end

      private

      def reserve
        Merit::Flex::SimpleReserve.new(
          total_value { @node.dataset_get(:storage).volume }
        )
      end
    end
  end
end
