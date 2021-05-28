# frozen_string_literal: true

# An interface for building a Refinery graph without needing to hold references to all the nodes, or
# repeatedly reference Refinery classes directly.
class TestGraphBuilder
  attr_reader :graph

  # Public: A simple helper for creating a graph in a spec.
  #
  # For example
  #
  #   TestGraphBuilder.prepare do |b|
  #     b.node(:hello)
  #     b.node(:goodbye)
  #     b.connect(:a, :b, :electricity)
  #   end
  #
  # Returns the builder.
  def self.build(&block)
    new.tap { |builder| yield builder }
  end

  def initialize
    @graph = Turbine::Graph.new
    @carrier_attrs = {}
  end

  # Public: Adds a node to the graph.
  #
  # key        - A unique key identifying the node.
  # properties - An optional hash of properties to be stored on the node.
  #
  # Returns the Refinery::Node
  def add(key, properties = {})
    @graph.add(Refinery::Node.new(key, properties))
  end

  # Public: Connects two nodes.
  #
  # from_thing - The node or node key from which the edge will be connected.
  # to_thing   - The node or node key to which the edge will be connected.
  # label      - The label identifying the edge carrier.
  # properties - An optional hash of properties to be stored on the edge.
  #
  # For example
  #
  #   # Connecting two instances of Refinery::Node.
  #   builder.connect(node_one, node_two, :electricity)
  #
  # Returns the Refinery::Edge.
  def connect(from_thing, to_thing, label, properties = {})
    from = fetch_or_create_node(from_thing)
    to = fetch_or_create_node(to_thing)

    from.connect_to(to, label, properties)
  end

  # Public: Fetches the node identified by the key.
  #
  # Returns a Refinery::Node or nil.
  def node(nodelike)
    @graph.node(nodelike.is_a?(Refinery::Node) ? nodelike.key : nodelike) ||
      raise("No such node in the graph: #{nodelike.inspect}")
  end

  # Public: Fetches the edge between two nodes. The nodes must already exist in the graph.
  #
  # from  - The key identifying the from node.
  # to    - The key identifying the from node.
  # label - An optional carrier label. If none is provided, the first matching edge between the two
  #         nodes will be returned. If a label is given, only an edge of the named carrier will be
  #         returned.
  #
  def edge(from, to, label = nil)
    source = node(from)
    target = node(to)
    candidates = label ? source.slots.out(label).edges : source.edges(:out)

    candidates.find { |edge| edge.to.key == target.key } ||
      raise("No such edge in the graph: #{from.inspect} -- #{label.inspect} -> #{to.inspect}")
  end

  # Public: Calculates the Refinery graph and converts it to the Qernel equivalents.
  #
  # See FromRefinery.
  #
  # Returns a Qernel::Graph.
  def to_qernel
    graph = FromRefinery.call(@graph)

    # Refinery graphs cannot represent carrier attributes (since they aren't needed to calculate
    # energy flows) so we add custom carrier attributes seperately.
    @carrier_attrs.each do |carrier_key, attrs|
      carrier = graph.carrier(carrier_key)
      attrs.each { |key, value| carrier.dataset_set(key, value) }
    end

    graph
  end

  def carrier_attrs(carrier, attrs)
    (@carrier_attrs[carrier] ||= {}).merge!(attrs)
  end

  private

  def fetch_or_create_node(thing)
    if thing.is_a?(Refinery::Node)
      @graph.node(thing.key) || @graph.add(thing)
    else
      @graph.node(thing) || @graph.add(Refinery::Node.new(thing))
    end
  end
end
