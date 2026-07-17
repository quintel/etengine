# frozen_string_literal: true

module Qernel
  # Per-graph-instance resolver for scheme-based sector queries.
  #
  # Present and future graphs (and the energy and molecule graphs) are separate
  # instances holding separate node objects, so each gets its own resolver via
  # the graph's `sector_map` accessor. The mapping and the (label, use) -> node
  # key index are read once from {Etsource::Sectors}; resolution turns node keys
  # into the live nodes of this graph.
  #
  # Dispatch and arity live in the GQL layer; aggregation lives on
  # {Qernel::Emissions}. This class answers two questions: which (label, use)
  # pairs, and which live nodes, belong to (scheme, values)?
  class Sectors
    def initialize(graph, mapping, node_index)
      @graph      = graph
      @mapping    = mapping
      @node_index = node_index
      @node_cache = {}
      @pair_cache = {}
    end

    # Public: Whether `scheme` names a classification scheme in the mapping.
    # Used by the EMISSIONS first-argument dispatch.
    def scheme?(scheme)
      @mapping.key?(normalize(scheme))
    end

    # Public: The unique (label, use) pairs falling under any of `values` of
    # `scheme`. Reads the mapping only, so it is independent of node labelling;
    # the EMISSIONS mapped form sums the store over these pairs.
    #
    # Raises Gql::UnknownSectorSchemeError / Gql::UnknownSectorValueError.
    def pairs(scheme, values)
      value_list = Array(values)
      key = [normalize(scheme), value_list.map { |value| normalize(value) }]

      @pair_cache[key] ||= resolve_pairs(scheme, value_list)
    end

    # Public: The live nodes of this graph whose (label, use) pair falls under
    # any of `values` of `scheme` (the union). A value which resolves to pairs
    # with no labelled nodes contributes nothing.
    def lookup(scheme, values)
      value_list = Array(values)
      key = [normalize(scheme), value_list.map { |value| normalize(value) }]

      @node_cache[key] ||=
        pairs(scheme, value_list).flat_map { |pair| nodes_for_pair(pair) }.uniq
    end

    # Public: The live nodes of this graph whose (label, use) pair equals
    # `pair` (an already-normalized [label, use]). Used by mapping-driven CSV
    # exports as well as {#lookup}.
    def nodes_for_pair(pair)
      Array(@node_index[pair]).filter_map { |key| @graph.node(key) }
    end

    private

    def resolve_pairs(scheme, value_list)
      value_map = @mapping[normalize(scheme)]
      raise Gql::UnknownSectorSchemeError.new(scheme, @mapping.keys) if value_map.nil?

      value_list.flat_map do |value|
        value_map[normalize(value)] ||
          raise(Gql::UnknownSectorValueError.new(scheme, value))
      end.uniq
    end

    def normalize(value)
      Atlas::SectorMapping.normalize(value)
    end
  end
end
