module Api
  module V3
    class ConverterPresenter
      include ConverterPresenterData

      def initialize(key = nil, scenario = nil)
        raise "Missing Converter Key" unless key
        raise "Missing Scenario" unless scenario
        @key      = key
        @scenario = scenario
        @gql      = @scenario.gql(prepare: true)
        @present  = @gql.present_graph.graph.converter(@key) rescue nil
        @future   = @gql.future_graph.graph.converter(@key) rescue nil
        @converter_api = @present.converter_api rescue nil
        @converter = @converter_api.converter
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

        json[:data] = {}

        attributes_and_methods_to_show.each_pair do |group, items|
          group_label = group.to_s.humanize
          json[:data][group_label] = {}

          items.each_pair do |attr, opts|
            pres = present_value(attr)
            fut = future_value(attr)
            next unless (pres || fut)
            next if pres <= 0.0 && opts[:hide_if_zero]

            pres = opts[:formatter].call(pres) if opts[:formatter]
            fut =  opts[:formatter].call(fut) if opts[:formatter]

            json[:data][group_label][attr] = {
              :present => pres,
              :future => fut,
              :unit => Qernel::ConverterApi.unit_for_calculation(attr) || opts[:unit],
              :desc => opts[:label]
            }
          end
        end

        # This boolean is used on the converter detail page to set some custom
        # text. I know it's ugly, but better adding one line here than low-level
        # details inside the view. PZ
        json[:uses_coal_and_wood_pellets] = uses_coal_and_wood_pellets?

        json
      end

      def present_value(attr)
        format_value @present, attr
      end

      def future_value(attr)
        format_value @future, attr
      end

      private

      def format_value(graph, attribute)
        # the instance_eval lets us pass arguments to methods
        graph.query.instance_eval(attribute.to_s)
      end
    end
  end
end
