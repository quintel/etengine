# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    # Looks up profiles and curves for use within Fever participants. Permits
    # the use of dynamic curves as defined in ETSource. Otherwise falls back to
    # first attempting to load from the heat CurveSet and finally from the
    # dataset load profile directory.
    class Curves
      def initialize(graph)
        @graph = graph
        @dataset = Atlas::Dataset.find(@graph.area.area_code)
      end

      def curve_set
        @curve_set ||= TimeResolve.curve_set(@graph.area, 'heat')
      end

      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      def curve(name, converter)
        name = name.to_s

        if name.start_with?('dynamic:')
          dynamic_profile(name[8..-1].strip.to_sym, converter)
        elsif curve_set.exists?(name)
          curve_set.curve(name)
        else
          @dataset.load_profile(name)
        end
      end

      private

      def dynamic_profile(name, converter)
        curve_conf = Etsource::Config.dynamic_curve(name)

        if curve_conf['type'] == 'amplify'
          Qernel::Plugins::Merit::Util.amplify_curve(
            @dataset.load_profile(curve_conf['curve']),
            converter.full_load_hours
          )
        else
          Qernel::Plugins::Merit::AggregateCurve.aggregate(mix_config(name))
        end
      end

      def mix_config(curve_name)
        curve_config(curve_name.to_sym)
          .each_with_object({}) do |(key, share), data|
            data[curve(key, nil)] = share
          end
      end

      def curve_config(name)
        components = Etsource::Config.dynamic_curve(name)['curves']

        components.each_with_object({}) do |component, config|
          config[component] = @graph.area.public_send("#{component}_share")
        end
      end
    end
  end
end
