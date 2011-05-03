class Qernel::ConverterApi

  def delta_in_capacity_in_mj_s
    return nil if required_attributes_contain_nil?(:delta_in_capacity_in_mj_s)
    (((production_based_on_number_of_plants.to_f / typical_production.to_f).to_f - (electricitiy_production_actual.to_f / typical_production.to_f).to_f) * typical_capacity_gross_in_mj_s.to_f).to_f
  end

  attributes_required_for :delta_in_capacity_in_mj_s, [
    :production_based_on_number_of_plants,
    :typical_production,
    :electricitiy_production_actual,
    :typical_capacity_gross_in_mj_s
    ]

  def peak_load_units_delta_for_mv_hv
    return nil if required_attributes_contain_nil?(:peak_load_units_delta_for_mv_hv)
    (number_of_plants_future - peak_load_units_present)

  end
  attributes_required_for :peak_load_units_delta_for_mv_hv, [:number_of_plants_future, :peak_load_units_present]

  def peak_load_heat_units_delta_for_mv_hv
    return nil if required_attributes_contain_nil?(:peak_load_units_delta_for_mv_hv)
    (number_of_heat_plants_future - peak_load_units_present)

  end
  attributes_required_for :peak_load_units_delta_for_mv_hv, [:number_of_heat_plants_future, :peak_load_units_present]


  def peak_load_capacity_delta_for_mv_hv
    return nil if required_attributes_contain_nil?(:peak_load_capacity_delta_for_mv_hv)
    (simult_we * peak_load_units_delta_for_mv_hv * typical_capacity_gross_in_mj_s)
  end

  attributes_required_for :peak_load_capacity_delta_for_mv_hv, [
    :simult_we,
    :peak_load_units_delta_for_mv_hv,
    :typical_capacity_gross_in_mj_s
    ]
end
