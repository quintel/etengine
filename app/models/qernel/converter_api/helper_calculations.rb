class Qernel::ConverterApi

  # Calculates the number of units that are installed in the future for this
  # converter, based on the demand (input) of the converter, the effective
  # input capacity and the full_load_seconds of the converter (to effectively)
  # convert MJ and MW
  #
  def number_of_units
    function(:number_of_units) do
      if ( effective_input_capacity == 0 || effective_input_capacity.nil? ||
           full_load_seconds == 0 || full_load_seconds.nil? )
        0
      else
        demand / (effective_input_capacity * full_load_seconds)
      end
    end
  end

  def total_land_use
    return nil if [number_of_units, land_use_per_unit].any?(&:nil?)
    number_of_units * land_use_per_unit
  end

  # Returns the number of households which are supplied by the energy created
  # in each unit. Used in DemandDriven converters for cases where a converter
  # may supply more than one building.
  #
  # If the dataset does not define an explicit value, this will default to 1.
  #
  # @return [Numeric]
  #   The number of buildings supplied with energy by this converter.
  #
  def households_supplied_per_unit
    function(:households_supplied_per_unit) { 1.0 }
  end

end
