module Qernel::Plugins
  module Merit
    # Helper class for creating and fetching curves related to the merit order.
    class Curves
      def self.curve_names
        [
          :ev_demand,
          :old_household_space_heating_demand,
          :new_household_space_heating_demand
        ]
      end

      def initialize(graph)
        @graph = graph
      end

      # Public: All dynamic curves combined into one.
      #
      # Returns a Merit::Curve.
      def combined
        @combined ||=
          self.class.curve_names.map { |name| public_send(name) }.reduce(:+)
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
          @graph.query.group_demand_for_electricity(:merit_ev_demand),
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
        @hw_demand ||= AggregateCurve.build(
          @graph.query.group_demand_for_electricity(
            :merit_household_hot_water_producers
          ),
          AggregateCurve.mix(dataset, dhw_normalized: 1.0)
        )
      end

      # Public: Describes the weighted average coefficient of performance of the
      # electric hot water producers.
      #
      # Returns a float.
      def household_hot_water_cop
        total = @graph.query.group_demand_for_electricity(
          :merit_household_hot_water_producers
        )

        converters = @graph.group_converters(
          :merit_household_hot_water_producers
        )

        converters.sum do |converter|
          api = converter.converter_api
          api.coefficient_of_performance * (api.input_of_electricity / total)
        end
      end

      # Public: The share of electrical technologies among all household hot
      # water producers.
      #
      # Returns a float.
      def share_of_electricity_in_household_hot_water
        producers = @graph.group_converters(
          :merit_household_hot_water_producers
        )

        outputs = producers.flat_map do |conv|
          conv.output(:useable_heat).links.map(&:lft_converter)
        end.uniq

        producers.map(&:converter_api).sum(&:output_of_useable_heat) /
          outputs.map(&:converter_api).sum(&:input_of_useable_heat)
      end

      # Public: Creates a profile describing the demand for electricity due to
      # heating and cooling in old households.
      def old_household_space_heating_demand
        heat_demand.curve_for(:old, dataset)
      end

      # Public: Creates a profile describing the demand for electricity due to
      # heating and cooling in new households.
      def new_household_space_heating_demand
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
