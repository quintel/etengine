# frozen_string_literal: true

# Creates CSV rows describing merit order production and consumption.
class HeatNetworkCSVSerializer
  attr_reader :filename

  def initialize(graph, conv_cust = nil)
    @filename = :heat_network
    @graph = graph
    @conv_cust = conv_cust
  end

  # Public: Creates an array of rows for a CSV file containing the loads of
  # heat producers and consumers.
  #
  # Returns an array of arrays.
  def to_csv_rows
    # Empty CSV if time-resolved calculations are not enabled.
    unless Qernel::Plugins::Causality.enabled?(@graph)
      return [['Merit order and time-resolved calculation are not ' \
               'enabled for this scenario']]
    end

    CurvesCSVSerializer.new(
      [*colums_for(:lt), *colums_for(:mt), *colums_for(:ht)],
      @graph.year,
      ''
    ).to_csv_rows
  end

  private

  def colums_for(network)
    serializer_for(network).raw_columns
  end

  def serializer_for(network)
    return ["Unknown network #{network}"] unless %i[lt mt ht].include?(network)

    MeritCSVSerializer.new(@graph, :steam_hot_water, :"heat_network_#{network}", @conv_cust, prefix: network)
  end
end
