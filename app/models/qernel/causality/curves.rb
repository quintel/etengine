# frozen_string_literal: true

module Qernel
  module Causality
    # Helper class for creating and fetching curves in time resolved plugins
    # such as Merit and Fever.
    class Curves
      def initialize(graph, rotate: 0)
        @graph = graph
        @rotate = rotate
      end

      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      def curve(name, node)
        rotate(load_curve(name, node))
      end

      # Public: Rotates the given curve by the number of hours specified.
      #
      # See Array#rotate.
      #
      # Returns a curve.
      def rotate(curve, count = @rotate)
        @rotate.zero? ? curve : curve.rotate(count)
      end

      # Public: De-rotates the given curve so that its first hour represents
      # January 1st 00:00.
      #
      # Returns a curve.
      def derotate(curve)
        rotate(curve, -@rotate)
      end

      private

      # Internal: Returns if the `curve_name` is prefixed with `prefix`.
      def prefix?(curve_name, prefix)
        curve_name.to_s.start_with?("#{prefix}:")
      end

      # Internal: Loads a curve without performing rotation.
      def load_curve(name, node = nil)
        if prefix?(name, 'dynamic')
          dynamic_profile(name.to_s[8..].strip.to_sym, node)
        elsif attached_curve?(name)
          attached_curve(name)
        elsif name.include?('/')
          curve_set_profile(name)
        else
          dataset.load_profile(name)
        end
      end

      # Internal: Determines if an attached curve matching the name is allowed to be used. Curves
      # for which the config has been removed are ignored, and we fallback to the loading the curve
      # from the CSV in ETSource.
      #
      # Returns a boolean.
      def attached_curve?(key)
        @graph.dataset_get(:custom_curves).key?(key)
      end

      # Internal: Loads a curve attached to the scenario, identified by its key.
      #
      # Returns a Merit::Curve.
      def attached_curve(key)
        Merit::Curve.new(@graph.dataset_get(:custom_curves).fetch(key))
      end

      # Internal: Loads a profile from a curve set.
      #
      # The profile name is expected to be in the form
      # "curve_set_name/curve_name", with the variant name being determined
      # automatically based on user values.
      #
      # Returns a Merit::Curve.
      def curve_set_profile(name)
        set_name, curve_name = split_curve_name(name)
        curve_set(set_name).curve(curve_name)
      end

      # Internal: Creates a dynamic curve based on the ETSource dynamic curves
      # config, and mixing profiles based on shares in the area or by amplifying
      # a "baseline" profile.
      #
      # Returns a Merit curve.
      def dynamic_profile(name, node)
        # Returns quickly if the node has no energy flow.
        return AggregateCurve.zeroed_profile if node.demand.zero?

        curve_settings = Etsource::Config.dynamic_curve(name)

        if curve_settings['type'] == 'amplify'
          amplify_curve(curve_settings['curve'], node)
        else
          AggregateCurve.build(curve_components(curve_settings['curves']))
        end
      end

      # Internal: Creates a dynamic curve by reading a heat curve or load
      # profile with the matching `name` and amplifying the curve to match the
      # full load hours of the given node.
      #
      # Returns a Merit::Curve.
      def amplify_curve(name, node)
        if node.nil?
          raise <<~MSG.gsub(/\s+/, ' ').strip
            Cannot use an "amplified" dynamic curve without providing a
            node (on #{name.inspect}). Did you try to use a dynamic curve
            within a dynamic curve?'
          MSG
        end

        Util.amplify_curve(load_curve(name), node.full_load_hours)
      end

      # Internal: Takes an array of curve names - components of an aggregate
      # curve and returns a configuration hash where each key is Merit::Curve
      # and each value the share of the component in the final aggregate.
      #
      # Returns a Hash.
      def curve_components(curve_names)
        curve_names.each_with_object({}) do |component, config|
          config[load_curve(component)] =
            # Strip any curve set name from the component name.
            @graph.area.public_send("#{split_curve_name(component).last}_share")
        end
      end

      # Internal: Splits a curve into an array containing two elements: the
      # curve set name (or nil if no curve set is specified) and the curve name.
      def split_curve_name(name)
        name.include?('/') ? name.split('/', 2) : [nil, name]
      end

      # Internal: Fetch the curve set variant for the curve set called `name`.
      def curve_set(name)
        CurveSet.for_area(@graph.area, name)
      end

      def dataset
        @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
      end
    end
  end
end
