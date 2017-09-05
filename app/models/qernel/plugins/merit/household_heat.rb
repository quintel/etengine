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
        type_share = profile_share_for(type)

        AggregateCurve.build(
          demand_of(type),
          curve_set.curve(:insulated_household) => type_share,
          curve_set.curve(:non_insulated_household) => 1.0 - type_share
        )
      end

      # Public: The total demand for electricity for heating technologies for
      # households of the given type; :old or :new.
      def demand_of(type)
        share_of(type) * demand_for_heat
      end

      # Public: The share of households of the given type; :old or :new.
      def share_of(type)
        type == :new ? share_of_new_households : share_of_old_households
      end

      def curve_set
        @curve_set ||=
          if @graph.plugin(:time_resolve)
            @graph.plugin(:time_resolve).curve_set('heat')
          else
            # If TimeResolve is disabled (as is the case when Merit is off),
            # fall back to the default curves.
            TimeResolve::CurveSet.with_dataset(
              Atlas::Dataset.find(@graph.area.area_code), 'heat', 'default'
            )
          end
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

      def demand_for_heat
        @demand_for_heat ||= begin
          sh_group = Etsource::Fever.data[:space_heating]

          if sh_group && sh_group[:consumer].present?
            sh_group[:consumer].sum do |key|
              @graph.converter(key).converter_api.input_of(:useable_heat)
            end
          else
            0.0
          end
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
        min = @graph.area.insulation_level_old_houses_min
        max = @graph.area.insulation_level_new_houses_max
        actual = @graph.area.public_send(:"insulation_level_#{type}_houses")

        (actual - min) / (max - min)
      end
    end
  end # Merit
end # Qernel::Plugins
