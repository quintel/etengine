# frozen_string_literal: true

module Qernel
  module NodeApi
    # Various helper methods for setting demand of nodes from GQL.
    module DemandHelpers
      EXPECTED_DEMAND_TOLERANCE = 0.001

      # Updates a (power plant) node demand by its electricity output.
      #
      # That means we have to divide by the conversion of the electricity slot. So that the
      # electricity output edge receive that value, otherwise one part would go away to losses.
      #
      # For example:
      #
      #     UPDATE(... , preset_demand_by_electricity_production, 1000)
      #
      #     1000 electricity --> +------+
      #                          | 1030 |
      #              30 loss --> +------+
      #
      def preset_demand_by_electricity_production=(value)
        set_preset_demand_by_carrier_production(value, :electricity)
      end

      # Updates a (hydrogen production plant) node demand by its hydrogen output.
      #
      # That means we have to divide by the conversion of the hydrogen slot. So that the hydrogen
      # output edge receive that value, otherwise one part would go away to losses.
      #
      # For example:
      #
      #     UPDATE(... , preset_demand_by_hydrogen_production, 1000)
      #
      #     1000 hydrogen --> +------+
      #                       | 1030 |
      #           30 loss --> +------+
      #
      def preset_demand_by_hydrogen_production=(value)
        set_preset_demand_by_carrier_production(value, :hydrogen)
      end

      # Is the calculated near the demand_expected_value?
      #
      # Returns nil if demand or expected is nil. Returns true if demand is within tolerance
      # EXPECTED_DEMAND_TOLERANCE.
      def demand_expected?
        expected = demand_expected_value

        return nil if demand.nil? || expected.nil?

        actual   = demand.round(4)
        expected = expected.round(4)

        return true if actual.to_f.zero? && expected.to_f.zero?

        (actual.to_f / expected - 1.0).abs < EXPECTED_DEMAND_TOLERANCE
      end

      private

      def set_preset_demand_by_carrier_production(value, carrier_key)
        output_slot = node.output(carrier_key)

        unless output_slot
          raise "UPDATE: preset_demand_by_#{carrier_key}_production could not find " \
                "#{carrier_key} output for #{key.inspect}"
        end

        node.preset_demand = value / output_slot.conversion
      end
    end
  end
end
