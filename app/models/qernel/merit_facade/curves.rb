# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Helper class for creating and fetching curves related to the merit order.
    class Curves < Causality::Curves
      def initialize(graph, household_heat)
        super(graph)
        @household_heat = household_heat
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

        if prefix?(name, 'fever-electricity-demand')
          fever_demand_curve(name[25..-1].strip.to_sym)
        elsif prefix?(name, 'fever-self')
          fever_self_curve(name[11..-1].strip.to_sym)
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

      # Public: Creates a dynamic curve which reads the demand from a Fever
      # participant.
      def fever_self_curve(name)
        raise "Unknown fever-self curve: #{name}" unless name == :input_curve
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
