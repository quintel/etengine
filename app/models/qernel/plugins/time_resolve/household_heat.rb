# frozen_string_literal: true

module Qernel::Plugins
  class TimeResolve
    # Provides a profile which describes the shape of space heating demand in
    # households.
    class HouseholdHeat
      GROUP_FORMAT = '%s_household_space_heating_demand'.freeze

      def self.group_name(type)
        format(GROUP_FORMAT, type).to_sym
      end

      def initialize(graph, curve_set)
        @graph = graph
        @curve_set = curve_set
      end

      # Public: Given demand, returns a curve which describes the demand
      # throughout the year.
      #
      # Returns a Merit::Curve
      def demand_curve(demand)
        demand_profile * demand
      end

      # Public: The demand profile for heat in households.
      #
      # Returns a Merit::Curve.
      def demand_profile
        Qernel::Plugins::Merit::AggregateCurve.aggregate(
          @curve_set.curve(:insulated_household) => insulated_share,
          @curve_set.curve(:non_insulated_household) => uninsulated_share
        )
      end

      private

      def uninsulated_share
        1.0 - insulated_share
      end

      def insulated_share
        share_of_old_households * profile_share_for(:old) +
          share_of_new_households * profile_share_for(:new)
      end

      # Internal: The share of households which are classed as "old".
      def share_of_old_households
        old_d = demand_for(:old)
        new_d = demand_for(:new)

        old_d.zero? && new_d.zero? ? 0.0 : old_d / (old_d + new_d)
      end

      # Internal: The share of households which are classed as "new".
      def share_of_new_households
        old = share_of_old_households
        old.zero? && demand_for(:new).zero? ? 0.0 : 1.0 - old
      end

      # Internal: The total demand for space heating in new or old households.
      def demand_for(type)
        @graph
          .group_converters(self.class.group_name(type))
          .sum(&:demand)
      end

      # Internal: Determines the share of insulation in the given type of
      # household (new or old).
      def profile_share_for(type)
        min    = @graph.area.insulation_level_old_houses_min
        max    = @graph.area.insulation_level_new_houses_max
        actual = @graph.area.public_send(:"insulation_level_#{type}_houses")

        (actual - min) / (max - min)
      end
    end
  end
end
