# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      def initialize(node, context)
        super
        @was = @node.demand
      end

      def share_in_total
        @share ||= @node.number_of_units / total_in_group
      end

      # How much has the consumer already been filled with
      def share_met
        @share_met ||= 0.0
      end

      # TODO: is this correct?
      # Injects share prior to calculation
      def inject_share_to_producer(producer, share)
        @share_met += share

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
          .detect { |e| e.rgt_node == producer_node_key }
          .share = share
      end

      def participant
        @participant ||= Fever::Consumer.new(demand_curve.to_a)
      end

      def inject!
        inject_curve!(:input) { participant.demand_curve }
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

      private

      def demand_curve
        @context.curves.curve(@config.curve, @node) * @node.demand
      end

      def number_of_units
        1.0
      end

      def total_in_group
        # TODO: Can be a method higher up so we don't have to this case for each consumer
        case @config.group
        when :space_heating then @node.dataset_get(:number_of_residences)
        when :households_hot_water then @node.dataset_get(:number_of_residences)
        when :buildings_space_heating then @node.dataset_get(:number_of_buildings)
        end
      end
    end
  end
end
