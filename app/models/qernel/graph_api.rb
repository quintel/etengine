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

  def use_merit_order_demands?
    Qernel::Plugins::MeritOrder.enabled?(graph)
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

  # Demand of electricity for all converters which do not belong
  # to the final_demand_group but nevertheless consume electricity.
  def non_final_demand_for_electricity
    graph.group_converters(:non_final_electricity_demand_converters).map(&:converter_api).map(&:input_of_electricity).compact.sum
  end

  # Public: The demand of electricity in the entire graph, including use in the
  # energy sector and losses caused by no exports.
  #
  # Returns a numeric.
  def total_demand_for_electricity
    final_demand_for_electricity + non_final_demand_for_electricity +
    electricity_losses_if_export_is_zero
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
  # demand_curve - The "total demand" curve describing total energy demand
  #                throughout the year.
  # capacity     - The total installed capacity, in MWh.
  # excludes     - Converters keys whose profiled demands should be subtracted
  #                from  the total demand curve prior to calculating LOLE. See
  #                merit#123 for an example of why this may be desirable.
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
  def loss_of_load_expectation(demand, capacity, excludes = [])
    graph.plugin(:merit).order.lole.expectation(
      demand_curve(demand), capacity, excludes)
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
    graph.plugin(:merit).order.lole.demand_curve(
      Atlas::Dataset.find(area.area_code).load_profile(:total_demand), demand
    )
  end

  #######
  private
  #######

  # Demand of electricity of the energy sector itself 
  # (not included in final_demand_for_electricity)
  def energy_sector_own_use_electricity
    graph.converter(:energy_power_sector_own_use_electricity).demand
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
    own_use_of_sector      = energy_sector_own_use_electricity
    converter              = graph.converter(:energy_power_hv_network_electricity)
    conversion_loss        = converter.output(:loss).conversion
    conversion_electricity = converter.output(:electricity).conversion

    (transformer_demand + own_use_of_sector) * conversion_loss / conversion_electricity
  end

end

end
