module Api
  module V3
    class ConverterStatsPresenter
      ATTRIBUTES = [
        :demand,
        :electricity_output_capacity,
        :number_of_units
      ].freeze

      attr_reader :key

      def initialize(key, gql)
        @key = key
        @gql = gql

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
