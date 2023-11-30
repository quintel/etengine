# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      include CalculableActivity

      def initialize(node, context)
        super
        @was = @node.demand
        # TODO: at the init we should set all edges shares to 0!!!
        # Then set them again -rigth? or is it not neccesary? how does future graph work? they are unset right?
      end

      # How much has the consumer already been filled with
      def share_met
        @share_met ||= 0.0
        # Of kan dat toch vanuit de summed edges zoals we in de vorige commit hadden?
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
        # TODO: this feels very very nasty, but I think we have to! Otherwise the
        # graph wil try to solve it himself based on something unknown
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
