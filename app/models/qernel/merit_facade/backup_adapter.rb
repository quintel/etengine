# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A dispatchable producer with unlimited capacity.
    class BackupAdapter < DispatchableAdapter
      private

      def full_load_hours_from_participant
        # Participant has infinite output capacity, so the FLH cannot be
        # calculated in Merit itself.
        participant.production / (
          output_capacity_per_unit *
          participant.number_of_units *
          3600
        )
      end

      def producer_attributes
        super.merge!(output_capacity_per_unit: Float::INFINITY)
      end

      def marginal_costs
        # Backup is always last.
        Float::INFINITY
      end
    end
  end
end
