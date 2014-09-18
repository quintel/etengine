module Qernel
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
  include DatasetAttributes

  attr_reader :graph

  dataset_accessors :enable_merit_order, :use_merit_order_demands

  # @param graph [Qernel::Graph]
  def initialize(graph)
    @graph = graph
  end

  def dataset_attributes
    graph.dataset_attributes
  end

  def dataset_key
    :graph
  end

  def enable_merit_order?
    enable_merit_order == 1.0
  end

  def use_merit_order_demands?
    graph.use_merit_order_demands?
  end

  def fce_enabled?
    graph.use_fce
  end

  def area
    graph.area
  end

  def year
    graph.year
  end

  def carrier(key)
    graph.carrier(key)
  end

  # NON GQL-able

  def residual_ldc
    graph.residual_ldc
  end

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

  # Demand of electricity for all final demand converters
  def final_demand_for_electricity
    graph.group_converters(:final_demand_group).map(&:converter_api).map(&:input_of_electricity).compact.sum
  end

  # Public: The demand of electricity in the entire graph, including use in the
  # energy sector and losses caused by no exports.
  #
  # Returns a numeric.
  def total_demand_for_electricity
    final_demand_for_electricity +
    electricity_losses_if_export_is_zero -
    reduction_in_own_use_if_export_is_zero
  end

  # @return [Integer] Difference between start_year and end_year
  #
  def number_of_years
    graph.number_of_years
  end

  def converter(key)
    graph.converter(key).query
  end

  # Public: Given a +demand+ placed on the graph, and a maximum per-hour load
  # +capacity+, determines the proportion of hours where demand exceeds
  # production capacity.
  #
  # For example
  #
  #   converter.loss_of_load_expectation(120, 100)
  #   # => 130
  #   # This means that for 130 hours in the year, the demand (120 MW) demand
  #   # exceeded available supply of 100 MW.
  #
  # Returns a Integer representing the number of hours where capacity was
  # exceeded.
  def loss_of_load_expectation(demand, capacity)
    demand_curve(demand).count { |point| point > capacity }
  end

  # Public: Takes the merit order load curve, and multiplies each point by the
  # demand of the converter, yielding the load on the converter over time.
  #
  # An optional +demand+ parameter can be used to build the curve, instead of
  # using the default "total_demand_for_electricity" value.
  #
  # Returns an array, each value a Numeric representing the converter demand in
  # a one-hour period.
  def demand_curve(demand = nil)
    demand ||= total_demand_for_electricity

    Atlas::Dataset.find(area.area_code)
      .load_profile(:total_demand)
      .values.map { |point| point * demand }
  end

  #######
  private
  #######


  # Computes the electricity losses AS IF there were no exports.
  # This is accomplished by using the (fixed) conversion efficiencies
  # of the HV network for electricity (effE) and losses (effL) and the
  # expected total demand of the network IF the merit order is activated
  # (transformer_demand + export (== 0)).
  #
  # +---------------------+
  # |                     |
  # |                     |
  # |   export            <--------+
  # |                     |        |
  # |                     |        |
  # +---------------------+        |
  #                                |
  # +---------------------+        |       +---------------------+
  # |                     |        +-------+                     |
  # |                     |                |                     |
  # |   MV trafo +        <----------------+      HV network     |
  # |   own_use_of_sector |                |                     |
  # |                     |        +-------+                     |
  # +---------------------+        |       +---------------------+
  #                                |
  # +---------------------+        |
  # |                     |        |
  # |                     |        |
  # |   loss              <--------+
  # |                     |
  # |                     |
  # +---------------------+
  #
  # To find the loss IF export is zero, we use the fact that the ratio of
  # loss and electricity coming from the HV network is fixed.
  # In math:
  # loss / (transformer_demand + export) == effL / effE
  #
  # Setting export == 0 (as would be the case if the MO module is enabled)
  # gives the loss:
  #
  # loss = transformer_demand * effL / effE
  #
  # NOTE: This is ONLY correct if import and export are NOT taken into account
  # in the MO module.
  #
  # returns [Float] the network losses for the electricity net.
  def electricity_losses_if_export_is_zero
    transformer_demand     = graph.converter(:energy_power_transformer_mv_hv_electricity).demand
    converter              = graph.converter(:energy_power_hv_network_electricity)
    conversion_loss        = converter.output(:loss).conversion
    conversion_electricity = converter.output(:electricity).conversion
    own_use                = graph.converter(:energy_power_sector_own_use_electricity).demand
    own_use_fraction       = own_use / (converter.demand * conversion_electricity)

    transformer_demand * conversion_loss / (1.0 - conversion_loss - conversion_electricity * own_use_fraction)
  end

  # Correction factor for the own use of electricity of the energy sector 
  # if export is zero.
  #
  # The own use converter (energy_power_sector_own_use_electricity) is included 
  # in the final_demand_for_electricity function because it is part of the
  # final_demand_group.
  #
  # Similar to the loss of the hv network, 
  # energy_power_sector_own_use_electricity has a demand that depends on the 
  # total demand of energy_power_hv_network_electricity.
  #
  # NOTE: This is ONLY correct if import and export are NOT taken into account
  # in the MO module.
  #
  # returns [Float] the reduction of demand in 
  # energy_power_sector_own_use_electricity AS IF export == 0.
  def reduction_in_own_use_if_export_is_zero
    own_use                     = graph.converter(:energy_power_sector_own_use_electricity).demand
    hv_network                  = graph.converter(:energy_power_hv_network_electricity)
    conversion_loss             = hv_network.output(:loss).conversion
    conversion_electricity      = hv_network.output(:electricity).conversion
    own_use_fraction            = own_use / (hv_network.demand * conversion_electricity)
    transformer_demand          = graph.converter(:energy_power_transformer_mv_hv_electricity).demand
    hv_demand_if_export_is_zero = transformer_demand / (1.0 - conversion_loss - conversion_electricity * own_use_fraction)
    own_use_if_export_is_zero   = hv_demand_if_export_is_zero * own_use_fraction * conversion_electricity

    own_use - own_use_if_export_is_zero
  end

end

end
