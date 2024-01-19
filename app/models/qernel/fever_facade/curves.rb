# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Looks up profiles and curves for use within Fever participants. Permits
    # the use of dynamic curves as defined in ETSource. Otherwise falls back to
    # first attempting to load from the heat CurveSet and finally from the
    # dataset load profile directory.
    class Curves < Causality::Curves
      # Traverse the graph to get the technology curve shares of connected producers
      # to mix the curve for consumers correctly
      # TODO: check if the shares are ok at this point!
      def mixed_consumer_curve(consumer)
        curve_shares = consumer.fever.curve.keys.index_with { |_| 0.0 }

        consumer.input(:useable_heat).edges.each do |edge|
          node = edge.rgt_node

          # Check if it's an aggregator node, if so we move one node to the right
          if node.key.to_s.include?('aggregator')
            node = node.input(:useable_heat).edges.find { |e| e.type == :share }.rgt_node
          end

          curve_shares[node.fever[:technology_curve_type]] += edge.share
        end

        Causality::AggregateCurve.build(
          curve_shares.transform_keys do |key|
            curve(consumer.fever.curve[key], consumer)
          end
        )
      end
    end
  end
end
