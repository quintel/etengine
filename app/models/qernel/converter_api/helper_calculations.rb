class Qernel::ConverterApi
  
  # How many units are required to fill demand.
  def number_of_units
    return 0 if typical_input_capacity == 0 or typical_input_capacity.nil?
    dataset_fetch_handle_nil(:number_of_units) do
      mw_input_capacity / typical_input_capacity
    end
  end
  attributes_required_for :number_of_units, [:mw_input_capacity, :typical_input_capacity]

  # RD: This method is used by the number_of_units_update in multicommand factory
  # I dont think this belongs here!
  def number_of_units=(val)
    dataset_set(:number_of_units, val)
  end

  def total_land_use 
    return nil if required_attributes_contain_nil?(:total_land_use)
    number_of_units * land_use_per_unit
  end
  attributes_required_for :total_land_use, [
    :number_of_units,
    :land_use_per_unit
  ]
  
end