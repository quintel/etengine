module Qernel::Plugins
  module Fever
    class DelegatedCapacityCurve
      include Enumerable

      def initialize(capacity, other)
        @capacity = capacity
        @other    = other
      end

      # Internal: Prevents Fever from trying to coerce the object into an array.
      def length
        @other.load_curve.length
      end

      # Internal: Prevents Fever from trying to coerce the object into an array.
      def to_curve
        self
      end

      def each
        if block_given?
          @other.load_curve.length.times { |frame| yield self[frame] }
        else
          enum_for(:each)
        end
      end

      def [](frame)
        remaining = @capacity - @other.load_at(frame)
        remaining <= 0 ? 0.0 : remaining
      end
    end
  end
end
