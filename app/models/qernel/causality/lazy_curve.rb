# frozen_string_literal: true

module Qernel
  module Causality
    # Acts like a Merit::Curve, while calculating values for each element using
    # a callable object.
    class LazyCurve
      include Enumerable
      delegate :each, to: :to_a

      def initialize(&callable)
        @callable = callable
        @values = Array.new(8760)
      end

      def to_a
        if @values.last.present?
          @values.length > length ? @values[0...length] : @values.dup
        else
          Array.new(length) { |frame| get(frame) }
        end
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
        @values[frame] ||= @callable.call(frame)
      end

      # For some reason, Merit calls curve#values#[]
      def values
        self
      end

      def rotate(*)
        raise NotImplementedError, "#{self.class.name} does not support rotate"
      end
    end
  end
end
