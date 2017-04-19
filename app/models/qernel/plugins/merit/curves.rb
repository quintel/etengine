module Qernel::Plugins
  module Merit
    # Helper class for creating and fetching curves related to the merit order.
    class Curves
      # InvalidMix = Class.new(RuntimeError)

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
          mix(
            ev1: @graph.area.electric_vehicle_profile_1,
            ev2: @graph.area.electric_vehicle_profile_2,
            ev3: @graph.area.electric_vehicle_profile_3
          )
        )
      end

      private

      def mix(curves)
        curves.each_with_object({}) do |(key, share), data|
          path = dataset.load_profile_path(key)
          next unless path.file?

          data[::Merit::LoadProfile.load(path)] = share
        end
      end

      def dataset
        @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
      end
    end # Curves
  end # Merit
end # Qernel::Plugins
