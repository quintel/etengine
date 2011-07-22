class Qernel::ConverterApi
  
  ### 21-07-2011:
  # TODO: rename the attribute 'land_use_in_nl' to 'land_use_per_unit'
  def total_land_use 
  	return nil if required_attributes_contain_nil?(:total_land_use)
  	number_of_units * land_use_in_nl
  end
   attributes_required_for :total_land_use, [
  	:number_of_units,
  	:land_use_in_nl]
end