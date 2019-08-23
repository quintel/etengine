# frozen_string_literal: true

module Qernel
  module FeverFacade
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      def initialize(converter, graph, dataset)
        super
        @was = @converter.demand
      end

      def participant
        @participant ||= Fever::Consumer.new(demand_curve.to_a)
      end

      def inject!
        @converter.dataset_lazy_set(:heat_input_curve) do
          participant.demand_curve
        end
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
        # Yuck.
        curve = @graph.plugin(:time_resolve).fever
          .curves.curve(@config.curve, @converter)

        curve * @converter.demand
      end

      def number_of_units
        1.0
      end
    end # ConsumerAdapter
  end
end
