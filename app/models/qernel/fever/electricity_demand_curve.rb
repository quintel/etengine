module Qernel
  module Fever
    # Reads from the electricity-based heat producers in Fever to detemine
    # Merit order demands.
    #
    # Expects one or more callable objects which are called with the frame
    # number and should return the demand for electricity in that frame.
    class ElectricityDemandCurve
      include Enumerable
      delegate :each, to: :to_a

      def self.from_adapters(adapters)
        new(
          adapters
            .select { |a| a.input?(:electricity) }
            .map { |a| a.demand_callable_for_carrier(:electricity) }
        )
      end

      def initialize(callables)
        @demand_callables = callables
      end

      def to_a
        Array.new(length) { |frame| get(frame) }
      end

      def length
        8760
      end

      def get(frame)
        self[frame]
      end

      def first
        get(0)
      end

      def [](frame)
        @demand_callables.sum(0.0) { |callable| callable.call(frame) }
      end

      # For some reason, Merit calls curve#values#[]
      def values
        self
      end
    end
  end
end
