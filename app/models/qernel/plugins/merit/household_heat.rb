module Qernel::Plugins
  module Merit
    # Helper class for determining curves for the demand for electricity due
    # to heating in households.
    class HouseholdHeat
      def initialize(graph)
        @graph = graph
      end

      def space_heating_demand
        fever_group(:space_heating).elec_demand_curve
      end

      def hot_water_demand
        fever_group(:hot_water).elec_demand_curve
      end

      private

      def fever_group(group_name)
        @graph.plugin(:time_resolve).fever.group(group_name)
      end
    end
  end # Merit
end # Qernel::Plugins
