# frozen_string_literal: true

module Qernel::Plugins
  module Fever
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      def initialize(converter, graph, dataset)
        super
        @was = @converter.demand
      end

      def participant
        @participant ||=::Fever::Consumer.new(demand_curve.to_a)
      end

      def inject!
        @converter.demand = participant.load_curve.sum * 3600 # MWh -> MJ
      end

      private

      def demand_curve
        if @config.curve.to_s.delete(' ') == 'dynamic:household_heat'
          # Yuck.
          @graph.plugin(:time_resolve).fever.curves.household_heat
        else
          TimeResolve.load_profile(@dataset, @config.curve) * @converter.demand
        end
      end
    end # ConsumerAdapter
  end
end
