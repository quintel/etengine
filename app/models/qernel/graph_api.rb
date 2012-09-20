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

  dataset_accessors :enable_merit_order

  # @param graph [Qernel::Graph]
  def initialize(graph)
    @graph = graph
  end

  def dataset_attributes
    @graph.dataset_attributes
  end

  def dataset_key
    :graph
  end

  def enable_merit_order?
    enable_merit_order == 1.0
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

  def residual_ldc
    @graph.residual_ldc
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

  # @return [Integer] Difference between start_year and end_year
  #
  def number_of_years
    graph.number_of_years
  end

  def converter(key)
    graph.converter(key).query
  end

  def graph
    @graph
  end
end

end
