class Qernel::ConverterApi
  
  # How many units are required to fill demand.
  def number_of_units
    dataset_fetch_handle_nil(:number_of_units) do
      # return 0 if typical_input_capacity == 0
      mw_input_capacity / typical_input_capacity
    end
  end
  attributes_required_for :number_of_units, [:mw_input_capacity, :typical_input_capacity]

  alias number_of_plants number_of_units

  ##
  # RD: This method is used by the number_of_units_update in multicommand factory
  # I dont think this belongs here!
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

  ### 21-07-2011:
  # TODO: rename the attribute 'land_use_in_nl' to 'land_use_per_unit'
  def total_land_use 
    return nil if required_attributes_contain_nil?(:total_land_use)
    number_of_units * land_use_in_nl
  end
  attributes_required_for :total_land_use, [
    :number_of_units,
    :land_use_in_nl
  ]

  
end