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
        # TODO: the number of residences only works for households! -> do something with the group
        @share ||= @node.dataset_get(:"number_of_#{@node.key}") / total_in_group
      end

      # How much has the consumer already been filled with
      def share_met
        # TODO: is there a better method for it?
        # And does this work, or are the shares already per-set?
        # And we need more like a memo here?
        @node.input_edges.sum(&:share)
      end

      # TODO: method: inject_share_to(producer)
      # check how merit does this!!!

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
        # Can be a method higher up so we don't have to this case for each consumer
        case @config.group
        when :household_space_heating then @node.dataset_get(:number_of_residences)
        when :households_hot_water then @node.dataset_get(:number_of_residences)
        when :buildings_space_heating then @node.dataset_get(:number_of_buildings)
        end
      end
    end
  end
end
