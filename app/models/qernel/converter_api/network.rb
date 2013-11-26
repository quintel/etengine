class Qernel::ConverterApi

  def delta_in_capacity_in_mw
    fetch_and_rescue(:delta_in_capacity_in_mw) do
      (number_of_units - peak_load_units_present) * electricity_output_capacity
    end
  end
  unit_for_calculation "delta_in_capacity_in_mw", 'MW'

  def peak_load_in_mw
    fetch_and_rescue(:peak_load_in_mw) do
      (electricity_output_conversion + electricity_input_conversion) *
        input_capacity * number_of_units
    end
  end
  unit_for_calculation "peak_load_in_mw", 'MW'

  def peak_load_units_delta_for_mv_hv
    fetch_and_rescue(:peak_load_units_delta_for_mv_hv) do
      (number_of_units - peak_load_units_present)
    end
  end
  unit_for_calculation "peak_load_units_delta_for_mv_hv", 'number'

  def peak_load_capacity_delta_for_mv_hv
    fetch_and_rescue(:peak_load_capacity_delta_for_mv_hv) do
      (simult_we * peak_load_units_delta_for_mv_hv * electricity_output_capacity)
    end
  end
  unit_for_calculation "peak_load_capacity_delta_for_mv_hv", 'MW'

  def peak_load_capacity_per_unit
    fetch_and_rescue(:peak_load_units_capacity_per_unit) do
      ( (electricity_input_conversion || 0.0) - (electricity_output_conversion|| 0.0) ) * (input_capacity|| 0.0)
    end
  end
  unit_for_calculation "peak_load_capacity_per_unit", 'MW'

end
