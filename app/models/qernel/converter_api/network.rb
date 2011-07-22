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
  # TODO: change typical_production_old to typical_electricity_production_per_unit
  def delta_in_capacity_in_mj_s
    dataset_fetch_handle_nil(:delta_in_capacity_in_mj_s) do
      (((output_of_electricity / typical_production_old).to_f - (electricitiy_production_actual / typical_production_old).to_f) * typical_electricity_production_capacity.to_f).to_f
    end
  end
  attributes_required_for :delta_in_capacity_in_mj_s, [
    :output_of_electricity,
    :typical_production_old,
    :electricitiy_production_actual,
    :typical_electricity_production_capacity
  ]

  def peak_load_units_delta_for_mv_hv
    dataset_fetch_handle_nil(:peak_load_units_delta_for_mv_hv) do
      (number_of_units - peak_load_units_present)
    end
  end
  attributes_required_for :peak_load_units_delta_for_mv_hv, [:number_of_plants, :peak_load_units_present]

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
  
  ##
  # TO BE REFACTORED 
  #
  def typical_production_old
    dataset_fetch_handle_nil(:typical_production_old) do
      capacity_factor * typical_capacity_effective_in_mj_s * SECS_PER_YEAR
    end
  end
  attributes_required_for :typical_production_old, [:capacity_factor, :typical_capacity_effective_in_mj_s]
  
end
