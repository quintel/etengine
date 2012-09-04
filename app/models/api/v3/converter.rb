module Api
  module V3
    class Converter
      def initialize(key = nil, scenario = nil)
        raise "Missing Converter Key" unless key
        raise "Missing Scenario" unless scenario
        @key      = key
        @scenario = scenario
        @gql      = @scenario.gql(prepare: true)
        @present  = @gql.present_graph.graph.converter(@key) rescue nil
        @future   = @gql.future_graph.graph.converter(@key) rescue nil
        if @present.nil? || @future.nil?
          raise "Converter not found! (#{@key})"
        end
      end

      def to_json(options = {})
        Jbuilder.encode do |json|
          json.key  @key
          json.sector @present.sector_key
          json.use @present.use_key
          json.groups @present.groups
          json.energy_balance_group @present.energy_balance_group
          json.attributes do |json|
            Qernel::ConverterApi::ATTRIBUTE_GROUPS.each_pair do |group, attrs|
              json.set! group do |json|
                attrs.each do |attr, attr_data|
                  desc, unit = attr_data
                  pres = format_value(@present, attr)
                  fut = format_value(@future, attr)
                  next unless (pres || fut)
                  json.set! attr do |json|
                    json.present pres
                    json.future fut
                    json.unit unit
                    json.desc desc
                  end
                end
              end
            end
          end
          json.calculations do |json|
            Qernel::ConverterApi.calculation_methods.sort.each do |attr|
              pres = format_value(@present, attr)
              fut = format_value(@future, attr)
              next unless (pres || fut)
              json.set!(attr) do |json|
                json.present pres
                json.future fut
                json.unit Qernel::ConverterApi.unit_for_calculation(attr)
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
