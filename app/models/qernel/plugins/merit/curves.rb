# frozen_string_literal: true

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

      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      def profile(name, converter)
        name = name.to_s

        if name.start_with?('fever-electricity-demand:')
          fever_demand_curve(name[25..-1].strip.to_sym)
        elsif name.start_with?('dynamic:')
          dynamic_profile(name[8..-1].strip.to_sym, converter)
        else
          dataset.load_profile(name)
        end
      end

      # Public: Reads an electricity demand curve from a Fever group.
      #
      # Note that the curve returned is a demand curve, not a load profile. When
      # Merit and Fever are enabled, this will typically return an
      # ElectricityDemandCurve where the values are populated as the Fever group
      # is calculated.
      def fever_demand_curve(name)
        @household_heat.curve(name)
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

      def dynamic_profile(name, converter)
        curve_conf = Etsource::Config.dynamic_curve(name)

        if curve_conf['type'] == 'amplify'
          Merit::Util.amplify_curve(
            dataset.load_profile(curve_conf['curve']),
            converter.full_load_hours
          )
        else
          AggregateCurve.aggregate(mix_config(dataset, name))
        end
      end

      def dataset
        @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
      end

      def mix_config(dataset, curve_name)
        AggregateCurve.mix(dataset, curve_config(curve_name.to_sym))
      end

      def curve_config(name)
        components = Etsource::Config.dynamic_curve(name)['curves']

        components.each_with_object({}) do |component, config|
          config[component] = @graph.area.public_send("#{component}_share")
        end
      end
    end # Curves
  end # Merit
end # Qernel::Plugins
