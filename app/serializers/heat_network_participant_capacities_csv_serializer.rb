# frozen_string_literal: true

# Creates a capacity CSV for all three heat network carriers (lt, mt, ht)
# combined into a single file, matching the structure of HeatNetworkCSVSerializer.
class HeatNetworkParticipantCapacitiesCSVSerializer
  attr_reader :filename

  def initialize(graph)
    @filename = :heat_network_capacities
    @graph = graph
  end

  def to_csv_rows
    unless Qernel::Plugins::Causality.enabled?(@graph)
      return [['Merit order and time-resolved calculation are not enabled for this scenario']]
    end

    header = %w[key installed_capacity peak_capacity]
    data_rows = %i[lt mt ht].flat_map do |network|
      MeritOrderCapacitiesCSVSerializer.new(
        @graph, :steam_hot_water, :"heat_network_#{network}", prefix: network
      ).to_csv_rows[1..]
    end

    [header, *data_rows]
  end
end
