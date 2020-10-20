module Qernel::Plugins
  # Based on the configuration of the Area, disables sectors of the graph by
  # setting the demand of all nodes - and constant edges - to zero.
  class DisableSectors
    include Plugin

    before :first_calculation, :disable_sectors

    def self.enabled?(graph)
      graph.energy? && graph.area.disabled_sectors.any?
    end

    def disable_sectors
      disabled = @graph.area.disabled_sectors

      @graph.nodes.each do |node|
        next unless disabled.include?(node.sector_key)

        if node.dataset_get(:number_of_units)
          node.dataset_set(:number_of_units, 0.0)
        end

        if node.sector_key != :energy || node.preset_demand
          node.demand = node.preset_demand = 0.0
        end

        node.input_edges.each do |edge|
          edge.share = 0.0 if edge.edge_type == :constant
        end
      end
    end
  end # DisableSectors
end # Qernel::Plugins
