require 'spec_helper'

RSpec.describe FromRefinery do
  # Builds a graph of five nodes.
  #
  #       [A1]
  #       /  \
  #     [B1] [B2]
  #       \  /  \
  #       [C1]  [C2]
  #
  # * All nodes are connected with an electricity carrier, except for B2->C2 which is connected
  #   with gas.
  #
  let(:original) { Turbine::Graph.new }

  let(:a1) { original.add(Refinery::Node.new(:a1, demand: 100.0)) }
  let(:b1) { original.add(Refinery::Node.new(:b1)) }
  let(:b2) { original.add(Refinery::Node.new(:b2)) }
  let(:c1) { original.add(Refinery::Node.new(:c1, demand: 50)) }
  let(:c2) { original.add(Refinery::Node.new(:c2)) }

  let(:graph) { described_class.call(original) }

  before do
    a1.connect_to(b1, :electricity, reversed: true, parent_share: 0.2, type: :share)
    a1.connect_to(b2, :electricity, reversed: true, parent_share: 0.8, type: :share)
    b1.connect_to(c1, :electricity, child_share: 0.4, type: :dependent)
    b2.connect_to(c1, :electricity, type: :share)
    b2.connect_to(c2, :gas, type: :overflow)
  end

  # Finds a Qernel::Edge between two nodes.
  def qernel_edge(graph, from_key, to_key)
    graph.node(from_key).output_edges.find { |edge| edge.lft_node.key == to_key } ||
      raise("Found no edge between #{from_key.inspect} and #{to_key.inspect}")
  end

  it 'creates a Qernel::Graph' do
    expect(graph).to be_kind_of(Qernel::Graph)
  end

  it 'creates a graph with five nodes' do
    expect(graph.nodes.length).to eq(5)
  end

  it 'creates a graph with two carriers' do
    expect(graph.carriers.length).to eq(2)
  end

  # Node demands
  # ------------

  it 'sets the demand of A1' do
    expect(graph.node(:a1).demand).to eq(100)
  end

  it 'sets the demand of B1' do
    expect(graph.node(:b1).demand).to eq(20)
  end

  it 'sets the demand of B2' do
    expect(graph.node(:b2).demand).to eq(80)
  end

  it 'sets the demand of C1' do
    expect(graph.node(:c1).demand).to eq(50)
  end

  it 'sets the demand of C2' do
    expect(graph.node(:c2).demand).to eq(50)
  end

  # Node groups
  # -----------

  it 'sets no groups on the nodes' do
    expect(graph.node(:a1).groups).to be_empty
  end

  context 'when the A1 node has groups defined' do
    let(:a1) do
      super().tap { |a1| a1.set(:groups, %w[one two three]) }
    end

    it 'sets the groups on A1' do
      expect(graph.node(:a1).groups).to eq(%w[one two three])
    end
  end

  # Edge shares
  # -----------

  it 'sets the share of A1->B1' do
    expect(qernel_edge(graph, :a1, :b1).share).to eq(0.2)
  end

  it 'sets the share of A1->B2' do
    expect(qernel_edge(graph, :a1, :b2).share).to eq(0.8)
  end

  it 'sets no share for B1->C1' do
    expect(qernel_edge(graph, :b1, :c1).share).to be_nil
  end

  it 'sets the share of B2->C1' do
    expect(qernel_edge(graph, :b2, :c1).share).to eq(0.6)
  end

  it 'sets the no share for B2->C2' do
    expect(qernel_edge(graph, :b2, :c2).share).to be_nil
  end

  # Edge demands
  # ------------

  it 'sets the demand of A1->B1' do
    expect(qernel_edge(graph, :a1, :b1).demand).to eq(20)
  end

  it 'sets the demand of A1->B2' do
    expect(qernel_edge(graph, :a1, :b2).demand).to eq(80)
  end

  it 'sets the demand of B1->C1' do
    expect(qernel_edge(graph, :b1, :c1).demand).to eq(20)
  end

  it 'sets the demand of B2->C1' do
    expect(qernel_edge(graph, :b2, :c1).demand).to eq(30)
  end

  it 'sets the demand of B2->C2' do
    expect(qernel_edge(graph, :b2, :c2).demand).to eq(50)
  end

  # Edge types
  # ----------

  it 'sets the type of A1->B1 to share' do
    expect(qernel_edge(graph, :a1, :b1).type).to eq(:share)
  end

  it 'sets the type of A1->B2 to share' do
    expect(qernel_edge(graph, :a1, :b2).type).to eq(:share)
  end

  it 'sets the type of B1->C1 to dependent' do
    expect(qernel_edge(graph, :b1, :c1).type).to eq(:dependent)
  end

  it 'sets the type of B2->C1 to share' do
    expect(qernel_edge(graph, :b2, :c1).type).to eq(:share)
  end

  it 'sets the type of B2->C2 to inversed_flexible' do
    expect(qernel_edge(graph, :b2, :c2).type).to eq(:inversed_flexible)
  end

  # Edge reversal
  # -------------

  it 'sets A1->B1 to be reversed' do
    expect(qernel_edge(graph, :a1, :b1)).to be_reversed
  end

  it 'sets A1->B2 to be reversed' do
    expect(qernel_edge(graph, :a1, :b2)).to be_reversed
  end

  it 'sets B1->C1 not to be reversed' do
    expect(qernel_edge(graph, :b1, :c1)).not_to be_reversed
  end

  it 'sets B2->C1 not to be reversed' do
    expect(qernel_edge(graph, :b2, :c1)).not_to be_reversed
  end

  it 'sets B2->C2 not to be reversed' do
    expect(qernel_edge(graph, :b2, :c2)).not_to be_reversed
  end

  # Slot conversions
  # ----------------

  it 'sets the electricity input on B1' do
    expect(graph.node(:b1).input(:electricity).conversion).to eq(1)
  end

  it 'sets the electricity output on B1' do
    expect(graph.node(:b1).output(:electricity).conversion).to eq(1)
  end

  it 'sets the electricity input on B2' do
    expect(graph.node(:b2).input(:electricity).conversion).to eq(1)
  end

  it 'sets the electricity output on B2' do
    expect(graph.node(:b2).output(:electricity).conversion).to eq(30.0 / 80)
  end

  it 'sets the gas output on B2' do
    expect(graph.node(:b2).output(:gas).conversion).to eq(50.0 / 80)
  end

  context 'when setting a custom slot share' do
    #    [C2] (demand: 50)
    #    /  \
    # [D1]  [D2]
    before do
      # c1.set(:demand, 100)
      # b1.out_edges.first.set(:child_share, 0.2)

      # node = original.node(:b2)
      # node.slots.out(:electricity).set(:share, 1.0)
      # node.slots.out(:gas).set(:share, 0.0)

      d1 = original.add(Refinery::Node.new(:d1))
      d2 = original.add(Refinery::Node.new(:d2))

      c2.connect_to(d1, :gas)
      c2.connect_to(d2, :electricity)

      c2.slots.out(:gas).set(:share, 0.3)
      c2.slots.out(:electricity).set(:share, 0.7)
    end

    it 'sets the custom gas output' do
      expect(graph.node(:c2).output(:gas).conversion).to eq(0.3)
    end

    it 'sets the custom electricity output' do
      expect(graph.node(:c2).output(:electricity).conversion).to eq(0.7)
    end
  end

  context 'when adding an edgeless slot' do
    before do
      c2.slots.out.add(:electricity, share: 0.8)
      c2.slots.out.add(:loss, share: 0.2)
    end

    it 'sets the electricity output' do
      expect(graph.node(:c2).output(:electricity).conversion).to eq(0.8)
    end

    it 'sets the loss output' do
      expect(graph.node(:c2).output(:loss).conversion).to eq(0.2)
    end
  end

  # Carriers
  # --------

  it 'sets the carrier key for electricity' do
    expect(graph.node(:b1).input(:electricity).edges.first.carrier.key).to eq(:electricity)
  end

  it 'sets the carrier key for gas' do
    expect(graph.node(:b2).output(:gas).edges.first.carrier.key).to eq(:gas)
  end
end
