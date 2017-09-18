module Qernel::Plugins
  module Merit
    # Helper class for determining curves for the demand for electricity due
    # to heating in households on graphs which do not use the full Merit/Fever
    # plugins.
    class SimpleHouseholdHeat
      def initialize(graph, curve_set)
        @graph = graph
        @curve_set = curve_set
      end

      # Public: Creates a curve describing the demand for electricity in
      # households due to the use of hot water.
      #
      # Returns a Merit::Curve.
      def hot_water_demand
        @hw_demand ||= AggregateCurve.build(
          @graph.query.group_demand_for_electricity(
            :merit_household_hot_water_producers
          ),
          AggregateCurve.mix(
            Atlas::Dataset.find(@graph.area.area_code),
            dhw_normalized: 1.0
          )
        )
      end

      # Public: Creates a curve describing the demadn for electricity in
      # households due to space heating.
      #
      # Returns a Merit::Curve.
      def space_heating_demand
        TimeResolve::HouseholdHeat.new(@graph, @curve_set)
          .demand_curve(demand_for_electricity)
      end

      private

      # Public: The total demand for electricity for heating technologies in
      # households.
      def demand_for_electricity
        @graph.query.group_demand_for_electricity(
          :merit_household_space_heating_producers
        )
      end
    end
  end # Merit
end # Qernel::Plugins
