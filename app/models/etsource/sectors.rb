# frozen_string_literal: true

module Etsource
  # Reads the sector mapping and node labels from Atlas and caches the two
  # structures GQL needs to resolve `SECTOR(scheme, value)` style queries.
  #
  # Mirrors the merit order import precedent: the expensive Atlas read happens
  # once and the result is memoized in the Rails cache, so per-request cost is a
  # couple of hash lookups.
  #
  #   * mapping        - {scheme => {value => [[label, use], ...]}}
  #   * node_index(g)  - {[label, use] => [node_key, ...]} for one graph type,
  #                      with `use` baked in at import so it is never consulted
  #                      per query.
  class Sectors
    def initialize(etsource = Etsource::Base.instance)
      @etsource = etsource
    end

    # Public: The inverted mapping index, keyed by scheme then normalized value.
    def mapping
      Rails.cache.fetch('sector_mapping_hash') do
        Atlas::SectorMapping.load.to_h
      end
    end

    # Public: The (label, use) -> node keys index for the given graph type
    # (:energy or :molecules).
    def node_index(graph_type)
      Rails.cache.fetch("sector_node_index_#{graph_type}") do
        build_node_index(node_class_for(graph_type))
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
