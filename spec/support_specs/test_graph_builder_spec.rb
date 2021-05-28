# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestGraphBuilder do
  context 'when adding a node' do
    let(:builder) do
      described_class.build do |builder|
        builder.add(:my_node, a: 1, b: 2)
      end
    end

    it 'adds the node' do
      expect(builder.node(:my_node)).not_to be_nil
    end

    it 'adds the properties' do
      expect(builder.node(:my_node).properties).to eq(a: 1, b: 2)
    end

    it 'can find the node with the node itself' do
      expect(builder.node(builder.node(:my_node))).not_to be_nil
    end

    it 'raises an error when fetching a node which does not exist' do
      expect { builder.node(:nope) }.to raise_error(/no such node/i)
    end
  end

  context 'when adding a duplicate node' do
    let(:builder) do
      described_class.build do |builder|
        builder.add(:my_node, a: 1, b: 2)
      end
    end

    it 'raises an error' do
      expect { builder.add(:my_node) }.to raise_error(Turbine::DuplicateNodeError)
    end
  end

  context 'when connecting two node objects with parallel edges' do
    let(:builder) do
      described_class.build do |builder|
        a = builder.add(:a)
        b = builder.add(:b)

        builder.connect(a, b, :electricity, c: 3)
        builder.connect(a, b, :gas, d: 4)
      end
    end

    let(:edge) do
      builder.node(:a).slots.out(:electricity).edges.first
    end

    it 'adds two edges' do
      expect(builder.node(:a).edges(:out).length).to eq(2)
    end

    it 'creates the connection' do
      expect(edge.to).to eq(builder.node(:b))
    end

    it 'sets the label' do
      expect(edge.label).to eq(:electricity)
    end

    it 'adds the properties' do
      expect(edge.properties).to eq(c: 3)
    end

    it 'can find the edge with keys' do
      expect(builder.edge(:a, :b)).to eq(edge)
    end

    it 'can find the edge with keys and a label' do
      expect(builder.edge(:a, :b, :electricity)).to eq(edge)
    end

    it 'can find a parallel edge with keys and a label' do
      expect(builder.edge(:a, :b, :gas)).not_to be_nil
    end

    it 'can find the edge with nodes' do
      expect(builder.edge(builder.node(:a), builder.node(:b))).to eq(edge)
    end

    it 'raises an error when adding a duplicate edge' do
      expect { builder.connect(:a, :b, :electricity) }.to raise_error(Turbine::DuplicateEdgeError)
    end

    it 'raises an error when fetching an edge which does not exist' do
      expect { builder.edge(:b, :a) }.to raise_error(/no such edge/i)
    end

    it 'raises an error when fetching an edge with an unused carrier' do
      expect { builder.edge(:a, :b, :nope) }.to raise_error(Refinery::NoSuchCarrierError)
    end

    it 'raises an error when fetching an edge to a node which does not exist' do
      expect { builder.edge(:b, :c) }.to raise_error(/no such node/i)
    end
  end

  context 'when customising carrier attributes' do
    let(:builder) do
      described_class.build do |builder|
        builder.connect(:a, :b, :gas, demand: 10)
        builder.carrier_attrs(:gas, co2_conversion_per_mj: 7.0)
      end
    end

    it 'sets the custom attributes on the Qernel graph' do
      expect(builder.to_qernel.carrier(:gas).co2_conversion_per_mj).to eq(7)
    end

    context 'when supplying additional attributes in a later call' do
      before do
        builder.carrier_attrs(:gas, potential_co2_conversion_per_mj: 10.0)
      end

      it 'sets the original attribute' do
        expect(builder.to_qernel.carrier(:gas).co2_conversion_per_mj).to eq(7)
      end

      it 'sets the new attribute' do
        expect(builder.to_qernel.carrier(:gas).potential_co2_conversion_per_mj).to eq(10)
      end
    end

    context 'when overriding an attribute in a later call' do
      before do
        builder.carrier_attrs(:gas, co2_conversion_per_mj: 10.0)
      end

      it 'sets the attribute with the latest value' do
        expect(builder.to_qernel.carrier(:gas).co2_conversion_per_mj).to eq(10)
      end
    end
  end
end
