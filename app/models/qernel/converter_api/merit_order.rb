# This is what they don't tell you at Software Engineering course.
#
class Qernel::ConverterApi
  def merit_order_variable_costs
    fetch_and_rescue(:merit_order_variable_costs) do
      merit_order_fuel_costs + merit_order_co2_emissions_costs +
        variable_operation_and_maintenance_costs
    end
  end
  unit_for_calculation "merit_order_variable_costs", 'euro / plant / year'

  def merit_order_fuel_costs
    fetch_and_rescue(:merit_order_fuel_costs) do
      typical_fuel_input * merit_order_weighted_carrier_cost_per_mj
    end
  end
  unit_for_calculation "merit_order_fuel_costs", 'euro / plant / year'

  def merit_order_co2_emissions_costs
    fetch_and_rescue(:merit_order_co2_emissions_costs) do
      typical_fuel_input * merit_order_weighted_carrier_co2_per_mj * area.co2_price *
        (1 - area.co2_percentage_free) * part_ets * ((1 - co2_free))
    end
  end
  unit_for_calculation "merit_order_co2_emissions_costs", 'euro / plant / year'

  def merit_order_weighted_carrier_co2_per_mj
    inputs.map do |slot|
      slot.conversion * slot.carrier.merit_order_co2_per_mj rescue 0
    end.compact.sum
  end

  def merit_order_weighted_carrier_cost_per_mj
    inputs.map do |slot|
      slot.conversion * slot.carrier.merit_order_cost_per_mj rescue 0
    end.compact.sum
  end
end