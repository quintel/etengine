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
        @producers.sum { |prod| prod.source_at(frame) }
      end

      def first
        get(0)
      end

      def [](frame)
        get(frame)
      end

      # For some reason, Merit calls curve#values#[]
      def values
        self
      end
    end
  end
end
