module Qernel::Plugins
  module Fever
    class DelegatedCapacityCurve
      include Enumerable

      def initialize(capacity, other, efficiency = 1.0)
        @capacity   = ::Fever.curve(capacity)
        @efficiency = ::Fever.curve(efficiency)
        @other      = other
      end

      # Internal: Prevents Fever from trying to coerce the object into an array.
      def length
        @other.output_curve.length
      end

      # Internal: Prevents Fever from trying to coerce the object into an array.
      def to_curve
        self
      end

      def each
        if block_given?
          @other.output_curve.length.times { |frame| yield self[frame] }
        else
          enum_for(:each)
        end
      end

      def [](frame)
        # Subtract from the capacity the amount of energy used by the aliased
        # producer *as if* it had been produced by the current producer. This
        # ensures that the different efficiencies of each producer is correctly
        # accounted for.
        adjusted_used = @other.source_at(frame) * @efficiency[frame]

        remaining = @capacity[frame] - adjusted_used
        remaining <= 0 ? 0.0 : remaining
      end
    end
  end
end
