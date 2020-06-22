# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Sets up and controls the calculation of one or more Fever instance.
    class Manager
      TYPES = %i[consumer storage producer].freeze

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

      def curves
        # Rotate curves so that the calculation is from April to March rather
        # than January to December.
        @curves ||= Curves.new(
          @graph,
          rotate: Qernel::Plugins::Causality::CURVE_ROTATE
        )
      end

      def summary(name)
        @summaries ||= {}
        @summaries[name.to_sym] ||= Summary.new(group(name))
      end

      # Configures the Fever groups, ensuring that hot water is first since its
      # producers may be used as aliases in other groups.
      def setup
        @groups =
          Etsource::Fever.groups.map do |conf|
            Group.new(conf.name, self)
          end
      end

      # Internal: Instructs each contained calculator to compute loads.
      #
      # Returns nothing.
      def calculate_frame(frame)
        @groups.each { |calc| calc.calculate_frame(frame) }
      end

      # Internal: Takes loads and costs from the calculated Merit order, and
      # installs them on the appropriate nodes in the graph. The updated
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
    end
  end
end
