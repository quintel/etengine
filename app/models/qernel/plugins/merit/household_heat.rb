module Qernel::Plugins
  module Merit
    # Helper class for determining curves for the demand for electricity due
    # to heating in households.
    class HouseholdHeat
      def initialize(graph)
        @graph = graph
      end

      # Public: The demand curve for electricity arising from heat demand for
      # households of the given type.
      #
      # Returns a Merit::Curve.
      def curve_for(type, dataset)
        AggregateCurve.build(
          demand_of(type),
          AggregateCurve.mix(
            dataset,
            insulated_household: profile_share_for(type),
            non_insulated_household: 1.0 - profile_share_for(type)
          )
        )
      end

      # Public: The total demand for electricity for heating technologies for
      # households of the given type; :old or :new.
      def demand_of(type)
        demand_for_electricity * share_of(type)
      end

      # Public: The share of households of the given type; :old or :new.
      def share_of(type)
        type == :new ? share_of_new_households : share_of_old_households
      end

      # Public: The total demand for electricity for heating technologies in
      # households.
      def demand_for_electricity
        @graph.query.group_demand_for_electricity(
          :merit_household_space_heating_producers
        )
      end

      # Public: The share of households which are classed as "old".
      def share_of_old_households
        @old_share ||= begin
          old_d = old_demand
          new_d = new_demand

          old_d.zero? && new_d.zero? ? 0.0 : old_d / (old_d + new_d)
        end
      end

      # Public: The share of households which are classed as "new".
      def share_of_new_households
        @new_share ||= begin
          old = share_of_old_households
          old.zero? && new_demand.zero? ? 0.0 : 1.0 - old
        end
      end

      private

      def old_demand
        @graph.group_converters(:merit_old_household_heat).sum(&:demand)
      end

      def new_demand
        @graph.group_converters(:merit_new_household_heat).sum(&:demand)
      end

      def profile_share_for(type)
        if type == :new
          @graph.area.insulation_profile_fraction_new_houses || 0.0
        else
          @graph.area.insulation_profile_fraction_old_houses || 1.0
        end
      end
    end
  end # Merit
end # Qernel::Plugins

