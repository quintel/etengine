module Qernel::Plugins
  module Fever
    # Defines a set of consumers and producers which will be computed in Fever.
    # For example, :space_heating or :hot_water. Each group is run in a separate
    # Fever instance.
    class Group
      attr_reader :name

      # Public: Creates a new Group.
      #
      # name    - The name of the group as a Symbol.
      # graph   - The Qernel::Graph containing the converters and demands.
      # dataset - Atlas::Dataset for the current region.
      #
      # Returns a Group.
      def initialize(name, plugin)
        @name    = name
        @graph   = plugin.graph
        @dataset = plugin.dataset
      end

      # Public: The Fever calculation which will compute the group.
      def calculator
        @calculator ||= ::Fever::Calculator.new(
          adapters_by_type[:consumer].first.participant,
          activities
        )
      end

      # Public: Instructs the calculator to compute a single frame.
      #
      # frame - The frame number to be calculated.
      #
      # Returns nothing.
      def calculate_frame(frame)
        calculator.calculate_frame(frame)
      end

      # Public: Returns a curve which describes the demand for electricity
      # caused by the activities within the calculator.
      def elec_demand_curve
        @elec_demand_curve ||=
          Qernel::Plugins::Fever::ElectricityDemandCurve.new(
            adapters.map { |a| a.producer_for_electricity_demand }.compact
          )
      end

      # Internal: The adapters which map converters from the graph to activities
      # within Fever.
      def adapters
        adapters_by_type.values.flatten
      end

      # Internal: Maps Fever types (:consumer, :storage, etc) to adapters.
      def adapters_by_type
        return @adapters if @adapters

        @adapters = Plugin::TYPES.each_with_object({}) do |type, data|
          data[type] =
            Etsource::Fever.group(@name).keys(type).map do |node_key|
              Adapter.adapter_for(@graph.converter(node_key), @graph, @dataset)
            end
        end
      end

      private

      def activities
        storage = adapters_by_type[:storage].map(&:participant)
        producers = adapters_by_type[:producer].map(&:participant)

        [storage, producers]
      end
    end # Group
  end # Fever
end
