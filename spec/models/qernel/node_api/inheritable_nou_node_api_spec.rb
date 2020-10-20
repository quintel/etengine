# frozen_string_literal: true

require 'spec_helper'

describe Qernel::NodeApi::InheritableNouNodeApi do
  describe 'when parent has 20 units' do
    let(:graph) do
      layout = <<-LAYOUT.strip_heredoc
        useable_heat: parent(100) == s(0.25) ==> child_one
        useable_heat: parent      == s(0.75) ==> child_two
      LAYOUT

      Qernel::GraphParser.new(layout).build
    end

    let(:parent)    { graph.nodes.detect { |c| c.key == :parent    } }
    let(:child_one) { graph.nodes.detect { |c| c.key == :child_one } }
    let(:child_two) { graph.nodes.detect { |c| c.key == :child_two } }

    before do
      allow(parent.node_api).to receive(:number_of_units).and_return(20.0)

      child_one.node_api = described_class.new(child_one)
      child_two.node_api = described_class.new(child_two)

      [child_one, child_two].each do |node|
        node.graph = graph
      end
    end

    it 'has 5 units when the node has a 25% share' do
      expect(child_one.node_api.number_of_units).to be(5.0)
    end

    it 'has 15 units when the node has a 75% share' do
      expect(child_two.node_api.number_of_units).to be(15.0)
    end

    it 'denies setting number of units' do
      expect { child_two.node_api.number_of_units = 2.0 }
        .to raise_error(NotImplementedError, /cannot set number of units/i)
    end
  end

  describe 'when parent has 20 units and 0.5 parent slot conversion' do
    let(:graph) do
      layout = <<-LAYOUT.strip_heredoc
        useable_heat[0.5]: parent(100) == s(0.6) ==> child_one
        electricity[0.5]:  parent      == s(1.0) ==> child_two
      LAYOUT

      Qernel::GraphParser.new(layout).build
    end

    let(:parent) { graph.nodes.detect { |c| c.key == :parent    } }
    let(:child)  { graph.nodes.detect { |c| c.key == :child_one } }

    before do
      allow(parent.node_api).to receive(:number_of_units).and_return(20.0)

      child.node_api = described_class.new(child)
      child.graph = graph
    end

    it 'has 10 units when the node has a 60% share' do
      expect(child.node_api.number_of_units).to eql(6.0)
    end
  end

  context 'when the node has no parent' do
    let(:graph) do
      layout = <<-LAYOUT.strip_heredoc
        useable_heat: parent(100) == s(0.25) ==> child_one
      LAYOUT

      Qernel::GraphParser.new(layout).build
    end

    let(:node) { graph.nodes.detect { |c| c.key == :parent } }

    before do
      node.node_api = described_class.new(node)
      node.graph = graph
    end

    it 'raises an error' do
      expect { described_class.new(node).number_of_units }
        .to raise_error(Qernel::NodeApi::InheritableNouNodeApi::InvalidParents)
    end
  end

  describe 'when parent has <nil> units' do
    let(:graph) do
      layout = <<-LAYOUT.strip_heredoc
        useable_heat: parent(100) == s(1.0) ==> child
      LAYOUT

      Qernel::GraphParser.new(layout).build
    end

    let(:parent) { graph.nodes.detect { |c| c.key == :parent } }
    let(:child)  { graph.nodes.detect { |c| c.key == :child } }

    before do
      allow(parent.node_api).to receive(:number_of_units).and_return(nil)

      child.node_api = described_class.new(child)
      child.graph = graph
    end

    it 'returns <nil> units' do
      expect(child.node_api.number_of_units).to be_nil
    end

    it 'returns a value once the parent has one' do
      expect { allow(parent.node_api).to receive(:number_of_units).and_return(20) }
        .to change { child.node_api.number_of_units }
        .from(nil).to(20)
    end
  end
end
