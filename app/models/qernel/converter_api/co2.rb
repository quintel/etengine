class Qernel::ConverterApi

  def primary_co2_emission
    converter.primary_co2_emission
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
