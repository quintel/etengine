# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    # Helper class for determining curves for the demand for useable heat by
    # space heating technologies in households.
    #
    # Unlike hot water, this curve is dynamic and depends on the share of new
    # and old households, and the amount of insulation installed in each.
    class HouseholdHeat
      def initialize(graph)
        @graph = graph
      end

      def demand_curve
        @graph.plugin(:time_resolve).household_heat
          .demand_curve(demand_for_heat)
      end

      private

      # Internal: The total demand for useable heat in households.
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
    end
  end # Fever
end # Qernel::Plugins
