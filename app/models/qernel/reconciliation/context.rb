# frozen_string_literal: true

module Qernel
  module Reconciliation
    # Encapsulates objects useful to the reconciliation calculation.
    Context =
      Struct.new(:dataset, :plugin, :graph, :carrier) do
        # Public: Fetches the configuration for a node, based on the context
        # carrier.
        #
        # Returns an Atlas::NodeAttributes::Reconciliation.
        def node_config(node)
          node.public_send(carrier)
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
          format(str, carrier)
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
          :"#{carrier}_#{direction}_curve"
        end
      end
  end
end
