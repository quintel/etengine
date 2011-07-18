class Qernel::ConverterApi

  def number_of_plants_planned=(val)
    dataset_set(:number_of_plants_future, val)
  end

  def production_based_on_number_of_plants
    dataset_fetch(:production_based_on_number_of_plants) do
      if required_attributes_contain_nil?(:production_based_on_number_of_plants)
        nil
      else
        number_of_plants * typical_production
      end
    end
  end
  attributes_required_for :production_based_on_number_of_plants, [:number_of_plants, :typical_production]

  def number_of_plants
    dataset_fetch(:number_of_plants) do
      if val = dataset_get(:number_of_plants_future)
        val
      elsif required_attributes_contain_nil?(:number_of_plants)
        nil
      else
        (output_of_electricity / ((typical_capacity_effective_in_mj_s * 8760 * 3600) * capacity_factor)).to_f
      end
    end
  end
  attributes_required_for :number_of_plants, [
    :typical_capacity_effective_in_mj_s,
    :capacity_factor
  ]

  def number_of_heat_plants_future
    dataset_fetch(:number_of_heat_plants_future) do
      return nil if required_attributes_contain_nil?(:number_of_heat_plants_future)

      # ((output_of_useable_heat + output_of_steam_hot_water + output_of_hot_water) / ((((typical_capacity_effective_in_mj_s / output_of_electricity) *(output_of_useable_heat + output_of_steam_hot_water + output_of_hot_water))* 8760 * 3600) * capacity_factor))
      ([output_of_useable_heat,output_of_steam_hot_water,output_of_hot_water].sum / ((typical_capacity_effective_in_mj_s* 8760 * 3600) * capacity_factor)).to_f
    end
  end
  attributes_required_for :number_of_heat_plants_future, [
    :typical_capacity_effective_in_mj_s,
    :capacity_factor
  ]

  def number_of_plants_future
    dataset_fetch(:number_of_plants_future) do
      if required_attributes_contain_nil?(:number_of_plants_future)
        nil
      else
        (output_of_electricity / ((typical_capacity_effective_in_mj_s * 8760 * 3600) * capacity_factor)).to_f
      end
    end
  end
  attributes_required_for :number_of_plants_future, [
    :typical_capacity_effective_in_mj_s,
    :capacity_factor
  ]
  
  def electricity_production_in_mw
    dataset_fetch(:electricity_production_in_mw) do
      if required_attributes_contain_nil?(:electricity_production_in_mw)
        nil
      else
        output_of_electricity / SECS_PER_YEAR / capacity_factor
      end
    end
  end
  attributes_required_for :electricity_production_in_mw, [
    :capacity_factor,
    :output_of_electricity
  ]

  def heat_production_in_mw
    dataset_fetch(:heat_production_in_mw) do
      if required_attributes_contain_nil?(:heat_production_in_mw)
        nil
      else
        [output_of_useable_heat,output_of_steam_hot_water,output_of_hot_water].sum  / SECS_PER_YEAR / capacity_factor
      end
    end
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
    dataset_fetch(:total_land_use) do
      if required_attributes_contain_nil?(:total_land_use)
        nil
      else
        (output_of_electricity / ((typical_capacity_effective_in_mj_s * 8760 * 3600) * capacity_factor)) * land_use_in_nl
      end
    end
  end
  attributes_required_for :total_land_use, [
    :installed_capacity_effective_in_mj_s,
    :typical_capacity_effective_in_mj_s,
    :capacity_factor,
    :land_use_in_nl,
  ]

  def cost_om_per_mj
    sum_unless_empty values_for_method(:cost_om_per_mj)
  end
  attributes_required_for :cost_om_per_mj, [:cost_om_fixed_per_mj, :cost_om_variable_ex_fuel_co2_per_mj,:cost_co2_capture_ex_fuel_per_mj,:cost_co2_transport_and_storage_per_mj]

  ##
  #
  #
  def typical_production
    dataset_fetch(:typical_production) do
      if required_attributes_contain_nil?(:typical_production)
        nil
      else
        capacity_factor * typical_capacity_effective_in_mj_s * SECS_PER_YEAR
      end
    end
  end
  attributes_required_for :typical_production, [:capacity_factor, :typical_capacity_effective_in_mj_s]


  def overnight_investment_total
    dataset_fetch(:overnight_investment_total) do
      if required_attributes_contain_nil?(:overnight_investment_total)
        nil
      else
        typical_capacity_gross_in_mj_s * (overnight_investment_ex_co2_per_mj_s + overnight_investment_co2_capture_per_mj_s)
      end
    end
  end
  attributes_required_for :overnight_investment_total, [
    :typical_capacity_gross_in_mj_s,
    :overnight_investment_co2_capture_per_mj_s,
    :overnight_investment_ex_co2_per_mj_s
  ]


  def depreciation
    dataset_fetch(:depreciation) do
      if required_attributes_contain_nil?(:depreciation)
        nil
      else
        overnight_investment_total / technical_lifetime / typical_production
      end
    end
  end
  attributes_required_for :depreciation, [:overnight_investment_total, :technical_lifetime, :typical_production]


  def finance_and_capital_cost
    dataset_fetch(:finance_and_capital_cost) do
      sum_unless_empty values_for_method(:finance_and_capital_cost)
    end
  end
  attributes_required_for :finance_and_capital_cost, [:depreciation, :cost_of_capital]


  def cost_of_capital
    dataset_fetch(:cost_of_capital) do
      if required_attributes_contain_nil?(:cost_of_capital)
        nil
      else
        construction_time = self.construction_time || 0.0
      
        if [ technical_lifetime, typical_production].any?{|val| val.nil? or val.to_f == 0.0}
          nil
        else
          (
            overnight_investment_total / 2 * wacc * (construction_time + technical_lifetime) / technical_lifetime
          ) / typical_production
        end
      end
    end
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
