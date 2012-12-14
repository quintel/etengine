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
    graph.fce_enabled?
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
    graph.group_converters(:final_demand_electricity).map(&:demand).compact.sum
  end

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
  # |   MV trafo          <----------------+      HV network     |
  # |                     |                |                     |
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

    transformer_demand * conversion_loss / conversion_electricity
  end

  # @return [Integer] Difference between start_year and end_year
  #
  def number_of_years
    graph.number_of_years
  end

  def converter(key)
    graph.converter(key).query
  end

end

end
