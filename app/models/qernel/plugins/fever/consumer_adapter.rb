module Qernel::Plugins
  module Fever
    # Represents a Fever participant which will describe total demand.
    class ConsumerAdapter < Adapter
      def initialize(converter, graph, dataset)
        super
        @was = @converter.demand
      end

      def participant
        @participant ||=
          ::Fever::Consumer.new((demand_curve * @converter.demand).to_a)
      end

      def inject!
        @converter.demand = participant.load_curve.sum * 3600 # MWh -> MJ
      end

      private

      def demand_curve
        TimeResolve.load_profile(@dataset, @config.curve)
      end
    end # ConsumerAdapter
  end
end
