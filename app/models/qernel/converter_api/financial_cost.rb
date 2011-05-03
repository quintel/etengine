class Qernel::ConverterApi

  def number_of_plants_planned=(val)
    dataset_set(:number_of_plants_future, val)
  end

  def production_based_on_number_of_plants
    return nil if required_attributes_contain_nil?(:production_based_on_number_of_plants)

    number_of_plants * typical_production
  end
  attributes_required_for :production_based_on_number_of_plants, [:number_of_plants, :typical_production]

  def number_of_plants
    if val = dataset_get(:number_of_plants_future)
      return val
    end
    return nil if required_attributes_contain_nil?(:number_of_plants)
    (output_of_electricity / ((typical_capacity_effective_in_mj_s * 8760 * 3600) * capacity_factor)).to_f
    # @installed_capacity_effective_in_mj_s / @typical_capacity_effective_in_mj_s
  end
  attributes_required_for :number_of_plants, [
    :typical_capacity_effective_in_mj_s,
    :capacity_factor
  ]

  def number_of_heat_plants_future
    return nil if required_attributes_contain_nil?(:number_of_heat_plants_future)

    # ((output_of_useable_heat + output_of_steam_hot_water + output_of_hot_water) / ((((typical_capacity_effective_in_mj_s / output_of_electricity) *(output_of_useable_heat + output_of_steam_hot_water + output_of_hot_water))* 8760 * 3600) * capacity_factor))
    ([output_of_useable_heat,output_of_steam_hot_water,output_of_hot_water].sum / ((typical_capacity_effective_in_mj_s* 8760 * 3600) * capacity_factor)).to_f
  end

  attributes_required_for :number_of_heat_plants_future, [
    :typical_capacity_effective_in_mj_s,
    :capacity_factor
  ]

  def number_of_plants_future
    return nil if required_attributes_contain_nil?(:number_of_plants_future)
    (output_of_electricity / ((typical_capacity_effective_in_mj_s * 8760 * 3600) * capacity_factor)).to_f
  end
  attributes_required_for :number_of_plants_future, [
    :typical_capacity_effective_in_mj_s,
    :capacity_factor
  ]
  
  def electricity_production_in_mw
    return nil if required_attributes_contain_nil?(:electricity_production_in_mw)
    output_of_electricity / SECS_PER_YEAR / capacity_factor
  end
  
  attributes_required_for :electricity_production_in_mw, [
    :capacity_factor,
    :output_of_electricity
  ]

  def heat_production_in_mw
    return nil if required_attributes_contain_nil?(:heat_production_in_mw)
    [output_of_useable_heat,output_of_steam_hot_water,output_of_hot_water].sum  / SECS_PER_YEAR / capacity_factor
  end
  
  attributes_required_for :heat_production_in_mw, [
    :capacity_factor
  ]
  ##
  # NOT NEEDED YET
  # def municipality_production_in_mw
  #   return nil if required_attributes_contain_nil?(:municipality_production_in_mw)
  #   municipality_demand / SECS_PER_YEAR / capacity_factor
  # end
  # 
  # attributes_required_for :municipality_production_in_mw, [
  #   :capacity_factor,
  #   :municipality_demand
  # ]
  # 
  # def national_production_in_mw
  #   return nil if required_attributes_contain_nil?(:national_production_in_mw)
  #   preset_demand / SECS_PER_YEAR / capacity_factor
  # end
  # 
  # attributes_required_for :national_production_in_mw, [
  #   :capacity_factor,
  #   :preset_demand
  # ]

  def total_land_use
    return nil if required_attributes_contain_nil?(:total_land_use)
    (output_of_electricity / ((typical_capacity_effective_in_mj_s * 8760 * 3600) * capacity_factor)) * land_use_in_nl
  end
  attributes_required_for :total_land_use, [
    :installed_capacity_effective_in_mj_s,
    :typical_capacity_effective_in_mj_s,
    :capacity_factor,
    :land_use_in_nl,
  ]

#  def capacity_factor_actual
#    return nil if required_attributes_contain_nil?
#
#    if @installed_capacity_effective_in_mj_s.to_i == 0
#      @capacity_factor
#    else
#      @electricitiy_production_actual / @installed_capacity_effective_in_mj_s
#    end
#  end
#  attributes_required_for :capacity_factor_actual, [:electricitiy_production_actual, :installed_capacity_effective_in_mj_s]


  def cost_om_per_mj
    sum_unless_empty values_for_method(:cost_om_per_mj)
  end
  attributes_required_for :cost_om_per_mj, [:cost_om_fixed_per_mj, :cost_om_variable_ex_fuel_co2_per_mj,:cost_co2_capture_ex_fuel_per_mj,:cost_co2_transport_and_storage_per_mj]

  ##
  #
  #
  def typical_production
    return nil if required_attributes_contain_nil?(:typical_production)

    capacity_factor * typical_capacity_effective_in_mj_s * SECS_PER_YEAR
  end
  attributes_required_for :typical_production, [:capacity_factor, :typical_capacity_effective_in_mj_s]


  def overnight_investment_total
    return nil if required_attributes_contain_nil?(:overnight_investment_total)

    typical_capacity_gross_in_mj_s * (overnight_investment_ex_co2_per_mj_s + overnight_investment_co2_capture_per_mj_s)
  end
  attributes_required_for :overnight_investment_total, [
    :typical_capacity_gross_in_mj_s,
    :overnight_investment_co2_capture_per_mj_s,
    :overnight_investment_ex_co2_per_mj_s
  ]


  def depreciation
    return nil if required_attributes_contain_nil?(:depreciation)

    overnight_investment_total / technical_lifetime / typical_production
  end
  attributes_required_for :depreciation, [:overnight_investment_total, :technical_lifetime, :typical_production]


  def finance_and_capital_cost
    sum_unless_empty values_for_method(:finance_and_capital_cost)
  end
  attributes_required_for :finance_and_capital_cost, [:depreciation, :cost_of_capital]


  def cost_of_capital
    return nil if required_attributes_contain_nil?(:cost_of_capital)
    construction_time = self.construction_time || 0.0

    return nil if [
      technical_lifetime,
      typical_production
    ].any?{|val| val.nil? or val.to_f == 0.0}

    (
      overnight_investment_total / 2 * wacc * (construction_time + technical_lifetime) / technical_lifetime
    ) / typical_production
  end
  attributes_required_for :cost_of_capital, [
    :overnight_investment_total,
    :technical_lifetime,
    :typical_production,
    :wacc
  ]
  
  def production_based_on_mw
    
  end
end
