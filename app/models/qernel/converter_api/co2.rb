class Qernel::ConverterApi

  ##
  # The co2 of all inputs *excluding* co2_free of this converter.
  #
  # @untested 2010-12-27 seb
  #
  def co2_of_input
    function(:co2_of_input) do
      co2_of_input = co2_of_input_including_co2_free
      co2_of_input = co2_of_input * (1 - co2_free) if co2_free
      co2_of_input = 0.0 if co2_of_input < 0
      co2_of_input += co2_of_fce_input
      co2_of_input
    end
  end

  ##
  # The co2 of all inputs *including* co2_free of this converter.
  #
  # @untested 2010-12-27 seb
  #
  def co2_of_input_including_co2_free
    function(:co2_of_input_including_co2_free) do
      converter.inputs.map do |input_slot|
        (input_slot.external_value || 0.0) * (input_slot.carrier.co2_conversion_per_mj || 0.0)
      end.compact.sum
    end
  end

  def co2_of_fce_input
    function(:co2_of_fce_input) do
      converter.inputs.map do |input_slot|
        (input_slot.external_value || 0.0) * (input_slot.carrier.co2_per_mj - input_slot.carrier.co2_conversion_per_mj || 0.0)
      end.compact.sum
    end
  end

  def co2_price
    function(:co2_price) do
      converter.graph.area.co2_price
    end
  end

  def co2_percentage_free
    function(:co2_percentage_free) do
      converter.graph.area.co2_percentage_free
    end
  end

  def primary_co2_emission
    converter.primary_co2_emission
  end

  def primary_co2_emission_for_carrier(carrier)
    carrier_key = carrier.respond_to?(:key) ? carrier.key : carrier
    primary_demand_co2_per_mj_of_carrier(carrier_key)
  end

  # This returns the costs for co2 emission credits, based on the CO2_per mwh input.
  def cost_of_co2_emission_credits
    function(:cost_of_co2_emission_credits) do
      cost_of_co2_emission_credits_per_mwh_input * mwh_input
    end
  end

  # This returns the costs for co2 emission credits per MWh input, as it multiplies the CO2 emitted by the converter by the price of the CO2 emissions.
  #
  def cost_of_co2_emission_credits_per_mwh_input
    function(:cost_of_co2_emission_credits_per_mwh_input) do
      (1 - self.area.co2_percentage_free ) * self.area.co2_price * part_ets * ((1 - co2_free) * weighted_carrier_co2_per_mj) * SECS_PER_HOUR
    end
  end

end
