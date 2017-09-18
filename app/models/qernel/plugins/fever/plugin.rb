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

      def household_heat
        @household_heat ||= HouseholdHeat.new(
          @graph,
          @graph.plugin(:time_resolve).curve_set('heat')
        )
      end

      # Configures the Fever groups, ensuring that hot water is first since its
      # producers may be used as aliases in other groups.
      def setup
        @groups =
          Etsource::Fever.data.keys
            .sort_by { |key| key == :hot_water ? 0 : 1 }
            .map { |key| Group.new(key, self) }
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
