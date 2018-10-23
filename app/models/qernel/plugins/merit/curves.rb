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

      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      def profile(name, converter)
        name = name.to_s

        return dataset.load_profile(name) unless name.start_with?('dynamic:')
        return AggregateCurve.zeroed_profile if converter.demand.zero?

        dyn_name = name[8..-1].strip.to_sym

        if respond_to?(dyn_name)
          public_send(dyn_name)
        else
          dynamic_profile(dyn_name, converter)
        end
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
