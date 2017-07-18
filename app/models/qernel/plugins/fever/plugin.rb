module Qernel::Plugins
  module Fever
    class Plugin
      def initialize(graph)
        @graph = graph
      end

      def calculator
        setup unless @calculator
        @calculator
      end

      # Public: Returns the Atlas dataset for the current graph region.
      def dataset
        @dataset ||= Atlas::Dataset.find(@graph.area.area_code)
      end

      def setup
        @calculator =
          if adapters.any?
            ::Fever::Calculator.new(
              adapters[:consumer].first.participant,
              adapters[:storage].map(&:participant) +
                adapters[:producer].map(&:participant)
            )
          else
            ::Fever::Calculator.new(::Fever::Consumer.new([]), [])
          end
      end

      # Internal: Returns an array of converters which are of the requested
      # merit order +type+ (defined in PRODUCER_TYPES).
      #
      # TODO Memoize this on Etsource like MeritOrder.
      #
      # Returns an array.
      def converters(type)
        Atlas::Node.all
          .select { |n| n.fever && n.fever.type == type }
          .map { |n| @graph.converter(n.key) }
      end

      # Internal: Takes loads and costs from the calculated Merit order, and
      # installs them on the appropriate converters in the graph. The updated
      # values will be used in the recalculated graph.
      #
      # Returns nothing.
      def inject_values!
        adapters.values.flatten.each(&:inject!)
      end

      private

      def adapters
        return @adapters if @adapters

        @adapters = Hash.new { |h, k| h[k] = [] }

        [:consumer, :storage, :producer].each do |type|
          converters(type).each do |converter|
            @adapters[type].push(Qernel::Plugins::Fever::Adapter.adapter_for(
              converter, @graph, dataset
            ))
          end
        end

        @adapters
      end
    end # Plugin
  end # Fever
end # Qernel::Plugins
