# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      include CalculableActivity

      def initialize(node, context)
        super
        @was = @node.demand
        # Set all edges to 0.0 to ensure that all edges set in the setup phase sum to 1.0
        # after calculating the consumer producer pairs
        @node.input(:useable_heat).edges.each { |e| e.share = 0.0 }
      end

      # How much has the consumer already been filled with (could also be sum of input_edges)
      def share_met
        @share_met ||= 0.0
      end

      # Injects share after to calculation
      def inject_share_to_producer(producer, share)
        prod_node = producer.node.node

        producer_node_key =
          if prod_node.groups.include?(:aggregator_producer)
            producer.node.output(:useable_heat).edges.first.lft_node.key
          else
            producer.node.key
          end

        @node
          .input(:useable_heat)
          .edges
          .detect { |e| e.rgt_node.key == producer_node_key }
          .share = share
      end

      def participant_for(tech_type, share)
        Fever::Consumer.new(demand_curve_for(tech_type, share).to_a)
      end

      def inject!
        # Inject shares again
        @node.input(:useable_heat).edges.each { |e| e.share = 0.0 }

        calculable_activities.each_value do |calc_activity|
          calc_activity.producers.each do |producer, share|
            inject_share_to_producer(producer, share)
          end
        end

        inject_curve!(:input) { demand_curve_from_activities }
      end

      def input?(*)
        false
      end

      def producer_for_carrier(_carrier)
        nil
      end

      def installed?
        true
      end

      def number_of_units
        @node.number_of_units
      end

      private

      def demand_curve_for(tech_type, demand_share)
        @context.curves.curve(@config.curve[tech_type], @node) * (@node.demand * demand_share)
      end

      def technology_curve_types
        @config.curve.keys
      end
    end
  end
end
