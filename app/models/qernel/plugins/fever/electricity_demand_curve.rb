module Qernel::Plugins
  module Fever
    # Reads from the electricity-based heat producers in Fever to detemine
    # Merit order demands.
    class ElectricityDemandCurve
      def initialize(adapters)
        @producers = adapters.each_with_object({}) do |adapter, data|
          data[adapter.participant.producer] =
            adapter.converter.electricity_input_conversion
        end
      end

      def to_a
        Array.new(8760) { |frame| get(frame) }
      end

      def get(frame)
        @producers.sum { |prod, conv| prod.input_at(frame) * conv }
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
