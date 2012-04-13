module Api
  module V3
    class Converter
      def initialize(code = nil, scenario = nil)
        raise "Missing Converter Key" unless code
        raise "Missing Scenario" unless scenario
        @code = code
        @scenario = scenario
        @gql = @scenario.gql(:prepare => true)
        @present = @gql.present_graph.graph.converter(key) rescue nil
        @future  = @gql.future_graph.graph.converter(key) rescue nil
        if @present.nil? || @future.nil?
          raise "Converter not found! (#{@code})"
        end
      end

      def to_json(options = {})
        Jbuilder.encode do |json|
          json.code @code
        end
      end
    end
  end
end
