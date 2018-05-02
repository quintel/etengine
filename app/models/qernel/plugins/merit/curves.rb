module Qernel::Plugins
  module Merit
    # Helper class for creating and fetching curves related to the merit order.
    class Curves
      CURVE_NAMES = [
        :ev_demand,
        :household_space_heating_demand
      ].freeze

      def initialize(graph, household_heat)
        @graph = graph
        @household_heat = household_heat
      end

      # Public: All dynamic curves combined into one.
      #
      # Returns a Merit::Curve.
      def combined
        @combined ||=
          Util.add_curves(CURVE_NAMES.map { |name| public_send(name) })
      end

      # Public: Returns the peak loads of explicitly modelled technologies.
      #
      # Returns a Hash
      def peaks
        @peaks ||= CurvePeakFinder.peaks(Util.add_curves(
          [combined, household_hot_water_demand]
        ))
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
          demand_value(:ev),
          AggregateCurve.mix(
            dataset,
            electric_vehicle_profile_1:
              @graph.area.electric_vehicle_profile_1_share,
            electric_vehicle_profile_2:
              @graph.area.electric_vehicle_profile_2_share,
            electric_vehicle_profile_3:
              @graph.area.electric_vehicle_profile_3_share
          )
        )
      end

      # Public: Creates a profile describing the demand for electricity in
      # households due to the use of hot water.
      #
      # Returns a Merit::Curve.
      def household_hot_water_demand
        @household_heat.hot_water_demand
      end

      # Public: Creates a profile describing the demand for electricity due to
      # heating and cooling in new households.
      def household_space_heating_demand
        @household_heat.space_heating_demand
      end

      # Public: Returns the total demand of the curve matching the +curve_name+.
      #
      # Returns a numeric.
      def demand_value(curve_name)
        if curve_name == :ev
          @graph.query.group_demand_for_electricity(:merit_ev_demand)
        else
          @household_heat.demand_value(curve_name)
        end
      end

      private

      def dataset
        @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
      end
    end # Curves
  end # Merit
end # Qernel::Plugins
