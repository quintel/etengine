module Api
  module V3
    class ConverterStatsPresenter
      ATTRIBUTES = [
        :demand,
        :electricity_output_capacity,
        :input_capacity,
        :number_of_units,
        :storage,
        :initial_investment,
        :technical_lifetime,
        :coefficient_of_performance,
        :full_load_hours,
        :fixed_operation_and_maintenance_costs_per_year,
        :variable_operation_and_maintenance_costs_per_full_load_hour,
        :variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour
      ].freeze

      attr_reader :key

      def initialize(key, gql)
        @key = key
        @gql = gql

        unless @gql.present_graph.converter(@key)
          fail "Missing converter: #{ @key }"
        end

        @present = @gql.present_graph.converter(@key).converter_api
        @future  = @gql.future_graph.converter(@key).converter_api
      end

      def as_json(*)
        ATTRIBUTES.each_with_object({}) do |attr_key, hash|
          hash[attr_key] = {
            present: @present.public_send(attr_key),
            future:  @future.public_send(attr_key)
          }
        end
      end
    end # ConverterStatsPresenter
  end # V3
end # Api
