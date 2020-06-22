module Api
  module V3
    class NodeStatsPresenter
      DEFAULTS = {
        demand: nil,
        electricity_output_capacity: nil,
        input_capacity: nil,
        number_of_units: nil,
        storage: nil,
        initial_investment: nil,
        technical_lifetime: nil,
        coefficient_of_performance: nil,
        full_load_hours: nil,
        fixed_operation_and_maintenance_costs_per_year: nil,
        variable_operation_and_maintenance_costs_per_full_load_hour: nil,
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour: nil,
      }

      ATTRIBUTES = {
        heat_output_capacity: nil,
        marginal_heat_costs: nil,

        fixed_operation_and_maintenance_costs_per_year_per_mw: -> conv {
          conv.fixed_operation_and_maintenance_costs_per(:mw_heat)
        },
        total_initial_investment_per_mw: -> conv {
          conv.total_initial_investment_per(:mw_heat)
        }
      }.freeze

      attr_reader :key

      def initialize(key, gql, graph_attributes)
        @key              = key
        @gql              = gql
        @graph_attributes = graph_attributes || DEFAULTS.keys

        unless @gql.present_graph.node(@key)
          fail "Missing node: #{ @key }"
        end

        unless @graph_attributes.all?(&method(:valid_attribute?))
          fail "Node attributes are not allowed for #{ key }"
        end

        @present = @gql.present_graph.node(@key).node_api
        @future  = @gql.future_graph.node(@key).node_api
      end

      def as_json(*)
        @graph_attributes.each_with_object({}) do |key, hash|
          key       = key.to_sym
          attribute = ATTRIBUTES[key] || key.to_proc

          hash[key] = {
            present: attribute.call(@present),
            future:  attribute.call(@future)
          }
        end
      end

      private

      def valid_attribute?(attr)
        (DEFAULTS.merge(ATTRIBUTES)).keys.include?(attr.to_sym)
      end
    end # NodeStatsPresenter
  end # V3
end # Api
