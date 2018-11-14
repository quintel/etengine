module Qernel::Plugins
  module Merit
    # Helper class for determining curves for the demand for electricity due
    # to heating in households.
    class HouseholdHeat
      def initialize(graph)
        @graph = graph
      end

      def curve(group_name)
        fever_group(group_name)&.elec_demand_curve ||
          AggregateCurve.zeroed_profile
      end

      # def space_heating_demand
      #   curve(:space_heating)
      # end

      # def hot_water_demand
      #   curve(:hot_water)
      # end

      # Public: Returns the total amount of demand for the group matching
      # +group_name+.
      def demand_value(group_name)
        group = fever_group(group_name)

        return 0.0 unless group

        group.adapters_by_type[:producer].sum do |adapt|
          adapt.converter.input_of_electricity
        end
      end

      private

      def fever_group(group_name)
        @graph.plugin(:time_resolve).fever.group(group_name)
      end
    end
  end # Merit
end # Qernel::Plugins
