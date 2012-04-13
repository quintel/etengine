module Api
  module V3
    class Converter
      def initialize(code = nil, scenario = nil)
        raise "Missing Converter Key" unless code
        raise "Missing Scenario" unless scenario
        @code = code
        @scenario = scenario
        @gql = @scenario.gql(:prepare => true)
        @present = @gql.present_graph.graph.converter(@code) rescue nil
        @future  = @gql.future_graph.graph.converter(@code) rescue nil
        if @present.nil? || @future.nil?
          raise "Converter not found! (#{@code})"
        end
      end

      def to_json(options = {})
        Jbuilder.encode do |json|
          json.code @code
          json.sector @present.sector_key
          json.use @present.use_key
          json.groups @present.groups
          json.energy_balance_group @present.energy_balance_group
          json.attributes Qernel::ConverterApi::ATTRIBUTE_GROUPS.keys do |json, group|
            json.set! group do |json|
              Qernel::ConverterApi::ATTRIBUTE_GROUPS[group].each do |attr|
                json.set! attr do |json|
                  json.present @present.send(attr) rescue nil
                  json.future @future.send(attr) rescue nil
                end
              end
            end
          end
        end
      end
    end
  end
end
