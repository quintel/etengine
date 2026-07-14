# frozen_string_literal: true

module Etsource
  # Reads the sector mapping and node labels from Atlas and caches the
  # structures GQL and the configured CSV exports need.
  #
  #   * mapping        - {scheme => {value => [[label, use], ...]}}, for
  #                      `SECTOR(scheme, value)` style GQL queries.
  #   * node_index(g)  - {[label, use] => [node_key, ...]} for one graph type,
  #                      with `use` baked in at import so it is never consulted
  #                      per query.
  #   * raw_rows       - mapping rows in file order with raw display values,
  #                      for mapping-driven CSV exports.
  class Sectors
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    # Public: The inverted mapping index, keyed by scheme then normalized value.
    def mapping
      NastyCache.instance.fetch('sector_mapping_hash') do
        Atlas::SectorMapping.load.to_h
      end
    end

    # Public: The (label, use) -> node keys index for the given graph type
    # (:energy or :molecules).
    def node_index(graph_type)
      NastyCache.instance.fetch("sector_node_index_#{graph_type}") do
        build_node_index(node_class_for(graph_type))
      end
    end

    # Public: Every mapping row in file order, as an Atlas::SectorMapping::RawRow
    # (the (label, use) pair plus the raw display value of every scheme cell).
    def raw_rows
      NastyCache.instance.fetch('sector_raw_rows') do
        Atlas::SectorMapping.load.raw_rows
      end
    end

    private

    def build_node_index(node_class)
      node_class.all.each_with_object({}) do |node, index|
        next if node.sector_label.nil?

        pair = [node.sector_label, Atlas::SectorMapping.normalize(node.use)]
        (index[pair] ||= []) << node.key
      end
    end

    def node_class_for(graph_type)
      graph_type.to_sym == :molecules ? Atlas::MoleculeNode : Atlas::EnergyNode
    end
  end
end
