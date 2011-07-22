class Qernel::ConverterApi

  def number_of_units=(val)
    dataset_set(:number_of_units, val)
  end

  ##
  # Removed production_based_on_number_of_plants, refactored to production_based_on_number_of_units
  # Added an alias untill the queries are altered
  #
  alias production_based_on_number_of_plants production_based_on_number_of_units

  ##
  # Removed number_of_plants, refactored to number_of_units
  # Added an alias untill the queries are altered
  #
  alias number_of_plants_future number_of_units

  ##
  # Removed number_of_heat_plants_future, refactored to number_of_units
  # Added an alias untill the queries are altered
  #

  alias number_of_heat_plants_future number_of_units
  

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

  ##
  #
  #
  def typical_production
    dataset_fetch_handle_nil(:typical_production) do
      capacity_factor * typical_capacity_effective_in_mj_s * SECS_PER_YEAR
    end
  end
  attributes_required_for :typical_production, [:capacity_factor, :typical_capacity_effective_in_mj_s]

end
