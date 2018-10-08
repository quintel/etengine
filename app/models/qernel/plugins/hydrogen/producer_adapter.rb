# frozen_string_literal: true

module Qernel::Plugins
  module Hydrogen
    class ProducerAdapter < Adapter
      def self.factory(converter, _context)
        if converter.hydrogen.behavior == :electrolyser
          ElectrolyserAdapter
        else
          self
        end
      end

      def inject!(_calculator)
        @converter.dataset_lazy_set(:hydrogen_output_curve) do
          demand_curve.to_a
        end
      end

      private

      def calculate_carrier_demand
        # We can't use output_of(:hydrogen) as the graph may not be calculated
        # at the time this method is called.
        @converter.demand * @converter.output(:hydrogen).conversion
      end
    end
  end
end
