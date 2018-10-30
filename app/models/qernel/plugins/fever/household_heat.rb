# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    # Helper class for determining curves for the demand for useable heat by
    # space heating technologies in households.
    #
    # Unlike hot water, this curve is dynamic and depends on the share of new
    # and old households, and the amount of insulation installed in each.
    module HouseholdHeat
      def self.demand_curve(graph)
        graph.plugin(:time_resolve).household_heat
          .demand_curve(demand_for_heat(graph))
      end

      # Internal: The total demand for useable heat in households.
      def self.demand_for_heat(graph)
        group = Etsource::Fever.group(:space_heating)

        return 0.0 unless group&.any_of_type?(:consumer)

        group.keys(:consumer).sum do |key|
          graph.converter(key).converter_api.input_of(:useable_heat)
        end
      end

      private_class_method :demand_for_heat
    end
  end # Fever
end # Qernel::Plugins
