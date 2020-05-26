# frozen_string_literal: true

module Qernel
  module Closud
    # Wraps around a Closud network, allowing for easier access in queries and
    # handles transforming load curves ensuring correct derotation.
    class Queryable
      DEFAULT_TRANSFORM = ->(curve) { curve }

      # Public: Creates a new Queryable
      #
      # network         - The fully-built Closud network.
      # curve_transform - A block which will receive each curve prior to
      #                   returning the value.
      def initialize(network, curve_transform = DEFAULT_TRANSFORM)
        @network = network
        @curve_transform = curve_transform
      end

      def demand_curve(layer_name)
        transform(layer(layer_name).demand_curve)
      end

      def load_curve(layer_name)
        transform(layer(layer_name).load_curve)
      end

      def supply_curve(layer_name)
        transform(layer(layer_name).supply_curve)
      end

      def peak_load(layer_name)
        layer(layer_name).peak_load
      end

      def inspect
        "#<#{self.class.name} (#{@network.to_h.keys.join(', ')})>"
      end

      private

      def transform(curve)
        @curve_transform.call(curve).to_a
      end

      def layer(layer_name)
        @network.dig(layer_name.to_sym) ||
          raise("No such network layer: #{layer_name.inspect}")
      end
    end
  end
end
