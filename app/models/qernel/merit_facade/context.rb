# frozen_string_literal: true

module Qernel
  module MeritFacade
    # Encapsulates objects useful to the merit calculation.
    class Context
      attr_reader :plugin, :graph, :carrier, :dispatchable_sorter

      delegate :curves, to: :plugin

      def initialize(plugin, graph, carrier, attribute, dispatchable_sorter)
        @plugin = plugin
        @graph = graph
        @carrier = carrier
        @attribute = attribute
        @dispatchable_sorter = dispatchable_sorter
      end

      def dataset
        @dataset ||= Atlas::Dataset.find(graph.area.area_code)
      end

      # Public: Fetches the configuration for a node, based on the context
      # carrier.
      #
      # Returns an Atlas::NodeAttributes::MeritOrder.
      def node_config(node)
        node.public_send(@attribute)
      end

      # Public: Interpolates a string with the name of the context carrier.
      #
      # str - The string to be formatted. "%s" will be replaced with the
      #       carrier name.
      #
      # For example:
      #
      #   context = Context.new(..., :hydrogen)
      #   context.carrier_named('%s_output_conversion')
      #   # => "hydrogen_output_conversion"
      #
      # Returns a String.
      def carrier_named(str)
        format(str, @carrier)
      end

      # Public: The name of a curve, based on the context carrier.
      #
      # direction - :input or :output
      #
      # For example:
      #
      #   context = Context.new(..., :hydrogen)
      #   context.curve_name(:input)
      #   # => :hydrogen_input_curve
      #
      # Returns a Symbol.
      def curve_name(direction)
        :"#{@carrier}_#{direction}_curve"
      end
    end
  end
end
