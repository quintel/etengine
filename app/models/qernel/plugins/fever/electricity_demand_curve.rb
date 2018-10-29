module Qernel::Plugins
  module Fever
    # Reads from the electricity-based heat producers in Fever to detemine
    # Merit order demands.
    class ElectricityDemandCurve
      include Enumerable
      delegate :each, to: :to_a

      def initialize(producers)
        @producers = producers
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
        @producers.sum(0.0) { |prod| prod.source_at(frame) }
      end

      # For some reason, Merit calls curve#values#[]
      def values
        self
      end
    end
  end
end
