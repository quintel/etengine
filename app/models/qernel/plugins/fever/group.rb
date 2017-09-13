module Qernel::Plugins
  module Fever
    class Group
      attr_reader :name

      def initialize(name, plugin)
        @name    = name
        @graph   = plugin.graph
        @dataset = plugin.dataset
      end

      def calculator
        @calculator ||= ::Fever::Calculator.new(
          adapters_by_type[:consumer].first.participant,
          activities
        )
      end

      def calculate_frame(frame)
        calculator.calculate_frame(frame)
      end

      def elec_demand_curve
        @elec_demand_curve ||=
          Qernel::Plugins::Fever::ElectricityDemandCurve.new(
            adapters.map { |a| a.producer_for_carrier(:electricity) }.compact
          )
      end

      def activities
        storage = adapters_by_type[:storage].map(&:participant)
        producers = adapters_by_type[:producer].map(&:participant)

        [storage, producers]
      end

      def adapters
        adapters_by_type.values.flatten
      end

      def adapters_by_type
        return @adapters if @adapters

        @adapters = Plugin::TYPES.each_with_object({}) do |type, data|
          data[type] =
            (Etsource::Fever.data[@name][type] || []).map do |node_key|
              Adapter.adapter_for(@graph.converter(node_key), @graph, @dataset)
            end
        end
      end
    end # Group
  end # Fever
end
