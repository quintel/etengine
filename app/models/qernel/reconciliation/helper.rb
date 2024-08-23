module Qernel
  module Reconciliation
    # A collection of helpful methods for working with reconciliation.
    module Helper
      module_function

      # Internal: Array describing the hourly carrier demand.
      def total_demand_curve(plugin)
        combined_curve(plugin, :consumer, :export, :input)
      end

      # Internal: Array describing the hourly carrier supply.
      def total_supply_curve(plugin)
        combined_curve(plugin, :producer, :import, :output)
      end

      # Public: Given the Reconciliation plugin, returns the balance of supply
      # and demand, excluding import, export, and storage. The returned float
      # will be positive if there is excess production, negative if a deficit.
      #
      # Returns a float.
      def supply_demand_balance(plugin)
        consumption = plugin
          .installed_adapters_of_type(:consumer)
          .sum(&:carrier_demand) +
          plugin
            .installed_adapters_of_type(:transformation)
            .sum(&:carrier_demand_input)

        production = plugin
          .installed_adapters_of_type(:producer)
          .sum(&:carrier_demand) +
          plugin
            .installed_adapters_of_type(:transformation)
            .sum(&:carrier_demand_output)

        production - consumption
      end

      # Internal: Creates the combined curves of two adapter groups.
      private_class_method def combined_curve(plugin, group_one, group_two, direction)
        ::Merit::CurveTools.add_curves((
            plugin.installed_adapters_of_type(group_one) +
            plugin.installed_adapters_of_type(group_two)
          ).map(&:demand_curve) +
            plugin.installed_adapters_of_type(:transformation).map(&:"demand_curve_#{direction}")
        ).to_a
      end
    end
  end
end
