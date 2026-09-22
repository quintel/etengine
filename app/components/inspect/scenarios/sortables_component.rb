# frozen_string_literal: true

module Inspect
  module Scenarios
    # Renders the user sortables -- the merit and dispatch orders -- which the user has changed
    # away from their default. Sortables left at their default say nothing about the scenario and
    # are not shown.
    class SortablesComponent < ApplicationComponent
      def initialize(scenario:)
        @scenario = scenario
      end

      # The sortables the user has changed away from their default.
      #
      # Returns an array of [label, UserSortable] pairs.
      def customised
        @customised ||= sortables.reject { |_, sortable| sortable.default? }
      end

      private

      # Every user sortable belonging to the scenario, each paired with its label, in the same
      # order as they appear in the scenario form.
      def sortables
        @sortables ||= [
          [label(:forecast_storage_order), @scenario.forecast_storage_order],
          [label(:hydrogen_supply_order), @scenario.hydrogen_supply_order],
          [label(:hydrogen_demand_order), @scenario.hydrogen_demand_order],
          [label(:heat_network_order_ht), @scenario.heat_network_order(:ht)],
          [label(:heat_network_order_mt), @scenario.heat_network_order(:mt)],
          [label(:heat_network_order_lt), @scenario.heat_network_order(:lt)],
          [
            label(:households_space_heating_producer_order),
            @scenario.households_space_heating_producer_order
          ]
        ]
      end

      def label(key)
        ScenariosController::SORTABLE_LABELS.fetch(key)
      end
    end
  end
end
