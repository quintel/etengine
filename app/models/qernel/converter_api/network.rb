class Qernel::ConverterApi
  def heating_peak_load_delta
    dataset_fetch_handle_nil(:heating_peak_load_delta) do
      simult_we *
      electricity_input_conversion *
      typical_electricity_production_capacity *
      share_of_heating_demand_households_energetic
    end
  end
  attributes_required_for :heating_peak_load_delta, [  
    :simult_we,
    :electricity_input_conversion,
    :typical_electricity_production_capacity,
    :share_of_heating_demand_households_energetic
  ]

  ##
  # TODO: change delta_in_capacity_in_mj_s to delta_in_capacity_in_mw in queries
  def delta_in_capacity_in_mw
    dataset_fetch_handle_nil(:delta_in_capacity_in_mw) do
      (number_of_units - peak_load_units_present) * typical_electricity_production_capacity 
    end
  end
  attributes_required_for :delta_in_capacity_in_mw, [
    :number_of_units,
    :peak_load_units_present,
    :typical_electricity_production_capacity
  ]
  alias delta_in_capacity_in_mj_s delta_in_capacity_in_mw


  def peak_load_units_delta_for_mv_hv
    dataset_fetch_handle_nil(:peak_load_units_delta_for_mv_hv) do
      (number_of_units - peak_load_units_present)
    end
  end
  attributes_required_for :peak_load_units_delta_for_mv_hv, [:number_of_units, :peak_load_units_present]

  ##
  # Removed peak_load_heat_units_delta_for_mv_hv, because number_of_heat_units is now the same as number_of_units
  # Added an alias untill the queries are altered
  #
  alias peak_load_heat_units_delta_for_mv_hv peak_load_units_delta_for_mv_hv

  def peak_load_capacity_delta_for_mv_hv
    dataset_fetch_handle_nil(:peak_load_capacity_delta_for_mv_hv) do
      (simult_we * peak_load_units_delta_for_mv_hv * typical_electricity_production_capacity)
    end
  end
  attributes_required_for :peak_load_capacity_delta_for_mv_hv, [
    :simult_we,
    :peak_load_units_delta_for_mv_hv,
    :typical_electricity_production_capacity
  ]
  
  def peak_load_capacity_per_unit
    dataset_fetch_handle_nil(:peak_load_units_capacity_per_unit) do
      ( (electricity_input_conversion || 0.0) - (electricity_output_conversion|| 0.0) ) * (typical_input_capacity|| 0.0)
    end
  end
  attributes_required_for :peak_load_capacity_per_unit, [:typical_input_capacity, :electricity_input_conversion, :electricity_output_conversion]

end
