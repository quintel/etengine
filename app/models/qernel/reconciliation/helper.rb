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
        total_consumption = sum_adapter_demand(plugin, :consumer, :carrier_demand) +
                            sum_adapter_demand(plugin, :transformation, :carrier_demand_input)
        total_production  = sum_adapter_demand(plugin, :producer, :carrier_demand) +
                            sum_adapter_demand(plugin, :transformation, :carrier_demand_output)

        total_production - total_consumption
      end

      # Internal: Creates the combined curves of two adapter groups.
      private_class_method def combined_curve(plugin, group_one, group_two, transformation)
        ::Merit::CurveTools.add_curves((
          plugin.installed_adapters_of_type(group_one) +
          plugin.installed_adapters_of_type(group_two)
        ).map(&:demand_curve) +
        plugin.installed_adapters_of_type(:transformation)
              .map(&:"demand_curve_#{transformation}")
      ).to_a
      end

      # Internal: Sums the specified carrier demand attribute over all adapters of a given type.
      #
      # plugin       - The plugin object that holds installed adapters.
      # adapter_type - The adapter type as a symbol (e.g. :consumer, :producer, or :transformation).
      # method_name  - The symbol representing the method to call on each adapter (e.g. :carrier_demand,
      #                :carrier_demand_input, :carrier_demand_output).
      #
      # Returns the sum of the demands (as a float).
      private_class_method def sum_adapter_demand(plugin, adapter_type, method_name)
        plugin.installed_adapters_of_type(adapter_type).sum(&method_name)
      end
    end
  end
end
