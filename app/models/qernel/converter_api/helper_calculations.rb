class Qernel::ConverterApi

  # DEBT: Remove this method if no longer used
  def number_of_units=(val)
    dataset_set(:number_of_units, val)
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
