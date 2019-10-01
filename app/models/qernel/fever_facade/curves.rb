# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Looks up profiles and curves for use within Fever participants. Permits
    # the use of dynamic curves as defined in ETSource. Otherwise falls back to
    # first attempting to load from the heat CurveSet and finally from the
    # dataset load profile directory.
    class Curves < Plugins::TimeResolve::Curves
      def initialize(graph)
        super(graph)
        # @dataset = Atlas::Dataset.find(graph.area.area_code)
      end

      # def curve_set
      #   @curve_set ||= Plugins::TimeResolve.curve_set(@graph.area, 'heat')
      # end

      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      # def curve(name, converter)
      #   if curve_set.curve?(name)
      #     curve_set.curve(name)
      #   else
      #     super
      #   end
      # end
    end
  end
end
