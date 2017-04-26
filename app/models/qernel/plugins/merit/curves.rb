module Qernel::Plugins
  module Merit
    # Helper class for creating and fetching curves related to the merit order.
    class Curves
      def initialize(graph)
        @graph = graph
      end

      # Public: Creates a profile describing the demand for electricity by
      # electric vehicles.
      #
      # Expects the graph to have been computed, with the EV car converter given
      # a demand, and a valid profile mix saved with the area.
      #
      # Returns a Merit::Curve.
      def ev_demand
        AggregateCurve.build(
          @graph.query.group_demand_for_electricity(:ev_demand),
          AggregateCurve.mix(
            dataset,
            ev1: @graph.area.electric_vehicle_profile_1,
            ev2: @graph.area.electric_vehicle_profile_2,
            ev3: @graph.area.electric_vehicle_profile_3
          )
        )
      end

      # Public: Creates a profile describing the demand for electricity due to
      # heating and cooling in old households.
      def old_household_heat_demand
        heat_demand.curve_for(:old, dataset)
      end

      # Public: Creates a profile describing the demand for electricity due to
      # heating and cooling in new households.
      def new_household_heat_demand
        heat_demand.curve_for(:new, dataset)
      end

      private

      def heat_demand
        @heat_demand ||= HouseholdHeat.new(@graph)
      end

      def dataset
        @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
      end
    end # Curves
  end # Merit
end # Qernel::Plugins
