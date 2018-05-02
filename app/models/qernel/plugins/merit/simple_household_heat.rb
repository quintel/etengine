module Qernel::Plugins
  module Merit
    # Helper class for determining curves for the demand for electricity due
    # to heating in households on graphs which do not use the full Merit/Fever
    # plugins.
    class SimpleHouseholdHeat
      CURVE_TO_GROUP = {
        hot_water: :merit_household_hot_water_producers,
        space_heating: :merit_household_space_heating_producers
      }.freeze

      def initialize(graph, curve_set)
        @graph = graph
        @curve_set = curve_set
      end

      # Public: Returns the total amount of demand for the curve matching the
      # +curve_name+.
      def demand_value(curve_name)
        @graph.query.group_demand_for_electricity(
          CURVE_TO_GROUP.fetch(curve_name)
        )
      end

      # Public: Creates a curve describing the demand for electricity in
      # households due to the use of hot water.
      #
      # Returns a Merit::Curve.
      def hot_water_demand
        @hw_demand ||= AggregateCurve.build(
          demand_value(:hot_water),
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
          .demand_curve(demand_value(:space_heating))
      end
    end
  end # Merit
end # Qernel::Plugins
