class Qernel::ConverterApi

  def delta_in_capacity_in_mw
    function(:delta_in_capacity_in_mw) do
      (number_of_units - peak_load_units_present) * typical_electricity_production_capacity
    end
  end
  unit_for_calculation "delta_in_capacity_in_mw", 'MW'

  def peak_load_in_mw
    function :peak_load_in_mw do
      (electricity_output_conversion + electricity_input_conversion) *
        typical_input_capacity_in_mw * number_of_units
    end
  end
  unit_for_calculation "peak_load_in_mw", 'MW'

  def peak_load_units_delta_for_mv_hv
    function(:peak_load_units_delta_for_mv_hv) do
      (number_of_units - peak_load_units_present)
    end
  end
  unit_for_calculation "peak_load_units_delta_for_mv_hv", 'number'

  def peak_load_capacity_delta_for_mv_hv
    function(:peak_load_capacity_delta_for_mv_hv) do
      (simult_we * peak_load_units_delta_for_mv_hv * typical_electricity_production_capacity)
    end
  end
  unit_for_calculation "peak_load_capacity_delta_for_mv_hv", 'MW'

  def peak_load_capacity_per_unit
    function(:peak_load_units_capacity_per_unit) do
      ( (electricity_input_conversion || 0.0) - (electricity_output_conversion|| 0.0) ) * (typical_input_capacity|| 0.0)
    end
  end
  unit_for_calculation "peak_load_units_capacity_per_unit", 'NW'

end
