# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      def initialize(node, context)
        super
        @was = @node.demand
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
    end
  end
end
