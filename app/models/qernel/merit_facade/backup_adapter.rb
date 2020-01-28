# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A dispatchable producer with unlimited capacity.
    class BackupAdapter < DispatchableAdapter
      def installed?
        true
      end

      private

      def full_load_hours_from_participant
        # Participant has infinite output capacity, so the FLH cannot be
        # calculated in Merit itself.
        participant.production / (
          output_capacity_per_unit *
          number_of_units_from_participant *
          3600
        )
      end

      def number_of_units_from_participant
        participant.load_curve.max / output_capacity_per_unit
      end

      def producer_attributes
        super.merge!(number_of_units: Float::INFINITY)
      end

      def marginal_costs
        # Backup is always last.
        Float::INFINITY
      end
    end
  end
end
