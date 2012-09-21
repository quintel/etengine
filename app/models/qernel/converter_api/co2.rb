class Qernel::ConverterApi

  def primary_co2_emission
    converter.primary_co2_emission
  end

  # This returns the costs for co2 emission credits of the converter,
  # based on the CO2_per mwh input.
  #
  # Used in total costs calculation of old cost calculation and some gqueries
  # to determine total costs of CO2 for electricity and heat.
  #
  # DEPRECATED
  #
  #def cost_of_co2_emission_credits
  #  function(:cost_of_co2_emission_credits) do
  #    cost_of_co2_emission_credits_per_mwh_input * mwh_input
  #  end
  #end
  #unit_for_calculation "cost_of_co2_emission_credits", 'euro'

  # This returns the costs for co2 emission credits per MWh input, as it
  # multiplies the CO2 emitted by the converter by the price of the 
  # CO2 emissions.
  #
  # Only used to calculate total CO2 emission cost per converter (see function
  # above) and in calculation of variable_costs_per_mwh_input.
  #
  # DEPRECATED
  #
  #def cost_of_co2_emission_credits_per_mwh_input
  #  function(:cost_of_co2_emission_credits_per_mwh_input) do
  #    (1 - self.area.co2_percentage_free ) * self.area.co2_price * part_ets * ((1 - co2_free) * weighted_carrier_co2_per_mj) * SECS_PER_HOUR
  #  end
  #end
  #unit_for_calculation "cost_of_co2_emission_credits_per_mwh_input", 'euro'

end
