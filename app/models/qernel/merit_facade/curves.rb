# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Helper class for creating and fetching curves related to the merit order.
    class Curves < Causality::Curves
      def initialize(graph, context, household_heat, rotate: 0)
        super(graph, rotate: rotate)

        @household_heat = household_heat
        @context = context
      end

      # Public: Retrieves the load profile or curve matching the given profile
      # name.
      #
      # For dynamic curves, a matching method name will be invoked if it exists,
      # otherwise it falls back to the dynamic curve configuration in ETSource.
      #
      # Returns a Merit::Curve.
      def curve(name, node)
        name = name.to_s

        # Fever and self curves come from Fever or another Merit instance and
        # are already rotated.
        if prefix?(name, 'fever-electricity-demand')
          fever_demand_curve(name[25..-1].strip.to_sym)
        elsif prefix?(name, 'self')
          self_curve(name[5..-1].strip.to_sym, node)
        else
          super
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

      # Internal: Reads a curve from another causality component (such as
      # electricity merit order reading heat network merit order).
      #
      # The curves from other calculations will be incomplete and only have
      # values available once that component has been calculated for the current
      # hour.
      #
      # Returns a Causality::LazyCurve.
      def self_curve(name, node)
        @self_curves ||= SelfCurves.new(@graph.plugin(:time_resolve), @context)
        @self_curves.curve(name, node)
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
    end
  end
end
