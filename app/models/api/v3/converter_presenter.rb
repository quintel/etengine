module Api
  module V3
    class ConverterPresenter
      def initialize(key = nil, scenario = nil)
        raise "Missing Converter Key" unless key
        raise "Missing Scenario" unless scenario
        @key      = key
        @scenario = scenario
        @gql      = @scenario.gql(prepare: true)
        @present  = @gql.present_graph.graph.converter(@key) rescue nil
        @future   = @gql.future_graph.graph.converter(@key) rescue nil
        @converter_api = @present.converter_api rescue nil
        if @present.nil? || @future.nil?
          raise "Converter not found! (#{@key})"
        end
      end

      def as_json(*)
        json = Hash.new

        json[:key]                  = @key
        json[:sector]               = @present.sector_key
        json[:use]                  = @present.use_key
        json[:groups]               = @present.groups
        json[:energy_balance_group] = @present.energy_balance_group

        json[:attributes] = {}

        @converter_api.relevant_attributes.each_pair do |group, attrs|
          json[:attributes][group] = {}

          attrs.each do |attr, attr_data|
            desc, unit = attr_data
            pres = format_value(@present, attr)
            fut = format_value(@future, attr)
            next unless (pres || fut)
            json[:attributes][group] = {
              :present => pres,
              :future => fut,
              :unit => unit,
              :desc => desc
            }
          end
        end

        # This boolean is used on the converter detail page to set some custom
        # text. I know it's ugly, but better adding one line here than low-level
        # details inside the view. PZ
        json[:uses_coal_and_wood_pellets] = @converter_api.uses_coal_and_wood_pellets?

        json[:calculations] = {}
        @converter_api.calculation_methods.each_pair do |group, methods|
          hsh = {}
          methods.each_pair do |method, opts|
            pres = format_value(@present, method)
            fut = format_value(@future, method)
            unit = Qernel::ConverterApi.unit_for_calculation(method)
            next unless (pres || fut)
            next if pres <= 0.0 && opts[:hide_if_zero]
            hsh[method] = {
              :present => pres,
              :future => fut,
              :unit => unit
            }
          end
          json[:calculations][group] = hsh
        end

        json
      end

      private

      def format_value(graph, attribute)
        graph.query.send(attribute)
        # Use instance_eval when we'll need to pass methods with parameters
        # graph.query.instance_eval(attribute.to_s)
      end
    end
  end
end
