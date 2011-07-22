class Qernel::ConverterApi

  ##
  # RD: This method is used by the number_of_units_update in multicommand factory
  # I dont think this belongs here
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
  # TO BE REFACTORED
  #
  def typical_production
    dataset_fetch_handle_nil(:typical_production) do
      capacity_factor * typical_capacity_effective_in_mj_s * SECS_PER_YEAR
    end
  end
  attributes_required_for :typical_production, [:capacity_factor, :typical_capacity_effective_in_mj_s]

end
