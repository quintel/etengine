module Qernel::Plugins
  module Fever
    class Plugin
      TYPES = [:consumer, :storage, :producer].freeze

      attr_reader :dataset
      attr_reader :graph

      def initialize(graph)
        @graph = graph
        @dataset = Atlas::Dataset.find(@graph.area.area_code)
      end

      def group(name)
        @groups.find { |c| c.name == name }
      end

      def groups
        @groups || setup
      end

      def setup
        @groups =
          Etsource::Fever.data.keys.map { |group| Group.new(group, self) }
      end

      # Internal: Instructs each contained calculator to compute loads.
      #
      # Returns nothing.
      def calculate_frame(frame)
        @groups.each { |calc| calc.calculate_frame(frame) }
      end

      # Internal: Takes loads and costs from the calculated Merit order, and
      # installs them on the appropriate converters in the graph. The updated
      # values will be used in the recalculated graph.
      #
      # Returns nothing.
      def inject_values!
        adapters.each(&:inject!)
      end

      private

      def adapters
        @groups.flat_map(&:adapters)
      end
    end # Plugin
  end # Fever
end # Qernel::Plugins
