# frozen_string_literal: true

module Qernel
  module MeritFacade
    # A dispatchable producer with unlimited capacity.
    class BackupAdapter < DispatchableAdapter
      private

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
