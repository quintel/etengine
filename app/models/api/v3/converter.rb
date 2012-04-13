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
          json.attributes do |json|
            Qernel::ConverterApi::ATTRIBUTE_GROUPS.each_pair do |group, attrs|
              json.set! group do |json|
                attrs.each do |attr|
                  json.set! attr do |json|
                    json.present format_value(@present, attr)
                    json.future format_value(@future, attr)
                  end
                end
              end
            end
          end
          json.calculations do |json|
            Qernel::ConverterApi.calculation_methods.sort.each do |name|
              json.set!(name) do |json|
                json.present format_value(@present, name)
                json.future format_value(@future, name)
              end
            end
          end
        end
      end

      def format_value(graph, attribute)
        graph.query.send(attribute) #rescue nil
      end
    end
  end
end
