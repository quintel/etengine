module Qernel

##
# Interface for a Qernel::Graph object to the outside world (GQL).
# The purpose was to proxy the access to the Qernel objects, so
#  that in future it might be easier to implement the graph for
#  instance in another language (C, Java, Scala).
#
# The GraphApi also includes a couple of more complicated queries
#  that would be too cumbersome for a GQL query.
#
class GraphApi
  include MethodMetaData

  ##
  # @param graph [Qernel::Graph]
  def initialize(graph)
    @graph = graph
  end

  def area
    @graph.area
  end

  def year
    @graph.year
  end

  def carrier(key)
    @graph.carrier(key)
  end

  # NON GQL-able

  ##
  # Still needed here, for updating converters
  #
  def potential_roof_pv_production
    c = graph.converter(:local_solar_pv_grid_connected_energy_energetic).query
    
    roof_surface        = area.roof_surface_available_pv
    land_use_per_unit   = c.land_use_per_unit
    production_per_unit = c.typical_electricity_production_per_unit
    
    if land_use_per_unit.nil?   || roof_surface.nil? || 
       production_per_unit.nil? || land_use_per_unit.zero?
      return nil 
    end
    (roof_surface / land_use_per_unit) * production_per_unit
  end
  attributes_required_for :potential_roof_pv_production, []

  def potential_roof_pv_production_buildings
    c = graph.converter(:solar_panels_buildings_energetic).query
    
    roof_surface        = area.roof_surface_available_pv_buildings
    land_use_per_unit   = c.land_use_per_unit
    production_per_unit = c.typical_electricity_production_per_unit
    
    if land_use_per_unit.nil?   || roof_surface.nil? || 
       production_per_unit.nil? || land_use_per_unit.zero?
      return nil 
    end
    (roof_surface / land_use_per_unit) * production_per_unit
  end
  attributes_required_for :potential_roof_pv_production_buildings, []

  def area_footprint
    graph.group_converters(:bio_footprint_calculation).map do |c|
      slot = c.outputs.reject(&:loss?).first
      demand = c.demand || 0.0
      if prod = slot.carrier.typical_production_per_km2
        demand / prod
      else
        0.0
      end
    end.flatten.compact.sum
  end


  def electricity_produced_from_gas
    @electricity_produced_from_gas = graph.group_converters(:electricity_production).select do |c|
      c.input(:gasmix) || c.input(:natural_gas)
    end.map{|c| 
      gasmix = c.input(:gasmix)
      nat_gas = c.input(:natural_gas)
      c.query.output_of_electricity * (gasmix and gasmix.conversion || nat_gas and nat_gas.conversion) 
    }.compact.sum
  end

  #
  # @return [Integer] Difference between start_year and end_year
  #
  def number_of_years
    # DEBT remove call to Current.scenario. add variable to graph dataset
    Current.scenario.years
  end

  def sustainability_of_production_group(group_key)
    sust = graph.group_converters(group_key).map do |c|
      c.query.useful_output * c.demand * c.query.sustainable_input_factor
    end.compact.sum
    total = graph.group_converters(group_key).map do |c|
      c.query.useful_output * c.demand
    end.compact.sum

    (total == 0.0) ? 0.0 : (sust / total)
  end

  def share_of_renewable_for_group(group_key)
    converters = graph.group_converters(group_key)
    sust = converters.map{|c| c.primary_demand_of_sustainable }.compact.sum
    total = converters.map{|c| c.primary_demand }.compact.sum

    total == 0.0 ? 0.0 : sust / total
  end

  # experimental. only uses the input of the involved converters not of primary
  def co2_emission_total_for_group(group_key)
    graph.group_converters(group_key).map(&:primary_co2_emission).compact.sum
  end


  ##
  # @return [Float] MT (Megatons) Co2 emission from primary energy
  #
  # Used in /admin/graphs/show
  #
  def co2_primary_emission_for_group(group_key)
    graph.group_converters(group_key).map(&:primary_co2_emission).compact.sum
  end


  ##
  # @return [Float] Percentage reduction of co2
  #
  def co2_reduction_in_percent(group, co2_1990)
    # co2_now / co2_1990 - 1
    co2_now  = co2_primary_emission_for_group(group)
    (co2_now - co2_1990) / co2_1990
  end




private
  def converter(key)
    graph.converter(key).query
  end

  def graph
    @graph
  end
end

end
