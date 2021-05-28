# frozen_string_literal: true

class FromRefinery
  # Creates an ETEngine graph using a Refinery graph.
  #
  # Values for nodes, edges, and carriers are installed on the ETEngine graph.A sparse graph may be
  # given (some demands or shares omitted), provided that enough information is given for Refinery
  # to calculate the rest.
  #
  # Returns a Qernel::Graph.
  def self.call(refinery_graph)
    new(refinery_graph).build
  end

  def initialize(refinery_graph)
    @refinery_graph = refinery_graph
  end

  def build
    calculate
    build_graph
  end

  private

  def calculate
    return if @calculated

    Refinery::Catalyst::Calculators.call(@refinery_graph)
    Refinery::Catalyst::Validation.call(@refinery_graph)

    @calculated = true
  end

  def build_graph
    @carriers = {}

    # Build nodes.
    nodes = @refinery_graph.nodes.map do |r_node|
      node = Qernel::Node.new(r_node.properties.merge(key: r_node.key, graph_name: :anonymous))

      (r_node.slots.in.to_a + r_node.slots.out.to_a).each do |r_slot|
        node.add_slot(build_node_slot(node, r_slot))
      end

      node.with(r_node.properties.except(:demand).merge(demand: r_node.demand.to_f))
    end

    build_edges(nodes)

    Qernel::Graph.new(nodes)
  end

  # Internal: Constructs a Qernel::Slot for the given Qernel::Node, using the Refinery::Slot.
  def build_node_slot(node, slot)
    Qernel::Slot.factory(
      slot.get(:type),
      "#{node.key}_#{slot.carrier}_#{slot.direction}",
      node,
      carrier(slot.carrier),
      :"#{slot.direction}put"
    ).with(conversion: slot.share.to_f)
  end

  # Internal: Given the Qernel::Nodes which will be members of the graph, constructs edges between
  # then as in the original Refinery graph. Also creates slots as necessary.
  def build_edges(nodes)
    indexed_nodes = nodes.index_by(&:key)

    @refinery_graph.nodes.flat_map { |n| n.edges(:out).to_a }.each do |r_edge|
      left = indexed_nodes[r_edge.to.key]
      right = indexed_nodes[r_edge.from.key]

      Qernel::Edge.new(
        "#{left.key} <- #{right.key} @ #{r_edge.label}",
        left,
        right,
        carrier(r_edge.label),
        edge_type(r_edge),
        r_edge.get(:reversed),
        r_edge.get(:groups)
      ).with(edge_properties(r_edge))
    end

    nil
  end

  # Internal: Returns the dataset object to be used by a Qernel::Edge based on the properties of the
  # given Refinery::Edge.
  def edge_properties(r_edge)
    props = r_edge.properties.except(:demand, :share)
    props[:value] = r_edge.demand.to_f

    if r_edge.get(:type) == :share
      props[:share] = (r_edge.get(:reversed) ? r_edge.parent_share : r_edge.child_share).to_f
    end

    props
  end

  # Internal: Given a Refinery edge, returns its equivalent Qernel type.
  def edge_type(r_edge)
    r_edge.get(:type) == :overflow ? :inversed_flexible : r_edge.get(:type) || :share
  end

  # Internel: Fetches or creates a carrier for the key.
  def carrier(key)
    @carriers[key] ||= Qernel::Carrier.new(key: key).with({})
  end
end
