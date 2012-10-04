module Qernel
  # Used for slots whose +conversion+ needs to be adjusted to reflect the
  # inputs provided to the converter.
  class Slot::CarrierEfficient < Slot

    # Public: Dynamically calculates +conversion+ based on the efficiency data
    # held by the converter. More efficient converter inputs will produce a
    # higher conversion.
    #
    # Returns a float.
    #
    def conversion
      function(:conversion) do
        input_keys = converter.inputs.map { |input| input.carrier.key }

        unless efficiencies = converter.dataset_get(:carrier_efficiency)
          raise InsufficientCarrierData.new(converter, input_keys, nil)
        end

        efficiencies = efficiencies[carrier.key] || {}

        unless Set.new(input_keys).subset?(Set.new(efficiencies.keys))
          raise InsufficientCarrierData.new(
            converter, input_keys, efficiencies.keys)
        end

        per_input = converter.inputs.map do |input|
          input.conversion * efficiencies[input.carrier.key]
        end

        per_input.sum
      end
    end

    # Internal: Raised when the converter does not have all of the carrier
    # efficiency data it needs.
    class InsufficientCarrierData < RuntimeError
      def initialize(converter, inputs, data)
        @converter, @inputs, @data = converter, inputs, data
      end

      def message
        if @data.nil?
          "Converter #{ @converter.inspect } has a carrier-efficient slot " \
            "but the :carrier_efficiency attribute is blank."
        else
          "Converter #{ @converter.inspect } has input slots " \
            "#{ @inputs.inspect } but only has carrier efficiency data for " \
            "#{ (@inputs & @data).inspect }."
        end
      end
    end # InsufficientCarrierData

  end # Slot::CarrierEfficient
end # Qernel
