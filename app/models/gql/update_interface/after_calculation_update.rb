module Gql::UpdateInterface

##
# After the future graph has been calculated, and before
# we run any updates, a few modifcations to the graph have to 
# be done. We can do this by directly changing the graph (not recommended)
# or by adding further update commands to the update command stack.
#
#
class AfterCalculationUpdate
  attr_reader :graph

  def initialize(graph)
    @graph = graph
  end

  def execute
    update_gasmix_prices
  end

  ##
  # Maybe this could be defined in Qernel::Carrier#cost_per_mj or co2_per_mj
  # As It doesn't involve any user input.
  #
  # THIS METHOD EXPLAINED:
  # Standard costs (and co2 emmissions) of gas carrier depends on gas and greengas. So these are mixed (and summed)
  #
  def update_gasmix_prices
    gasmix = graph.carrier(:gasmix)

    return if gasmix.nil? or graph.converter(:energy_sector_gas_mixer_energy).nil? # Needed for specs to run

    gasmix.cost_per_mj = graph.converter(:energy_sector_gas_mixer_energy).inputs.map do |slot|
      slot.conversion * slot.carrier.cost_per_mj
    end.compact.sum
    #gasmix.co2_per_mj = graph.converter(:energy_sector_gas_mixer_energy).inputs.map do |slot|
    #   slot.conversion * slot.carrier.co2_per_mj
    #end.compact.sum
  end

end

end
