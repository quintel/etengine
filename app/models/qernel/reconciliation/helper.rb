module Qernel
  module Reconciliation
    # A collection of helpful methods for working with reconciliation.
    module Helper
      module_function

      # Internal: Array describing the hourly carrier demand.
      def total_demand_curve(plugin)
        combined_curve(plugin, :consumer, :export)
      end

      # Internal: Array describing the hourly carrier supply.
      def total_supply_curve(plugin)
        combined_curve(plugin, :producer, :import)
      end

      # Public: Given the Reconciliation plugin, returns the balance of supply
      # and demand, excluding import, export, and storage. The returned float
      # will be positive if there is excess production, negative if a deficit.
      #
      # Returns a float.
      def supply_demand_balance(plugin)
        consumption = plugin
          .installed_adapters_of_type(:consumer)
          .sum(&:carrier_demand)

        production = plugin
          .installed_adapters_of_type(:producer)
          .sum(&:carrier_demand)

        #  TODO: add transformation here

        production - consumption
      end

      # Internal: Creates the combined curves of two adapter groups.
      private_class_method def combined_curve(plugin, group_one, group_two)
        ::Merit::CurveTools.add_curves((
          plugin.installed_adapters_of_type(group_one) +
          plugin.installed_adapters_of_type(group_two)
        ).map(&:demand_curve)).to_a
      end
    end
  end
end
