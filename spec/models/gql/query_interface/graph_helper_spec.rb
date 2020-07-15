# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'a delegated GraphHelper method' do
  let(:graph_method_name) { method_name }

  context 'with one key' do
    before do
      allow(graph).to receive(graph_method_name)
    end

    it 'calls the graph method once' do
      described_class.public_send(method_name, graph, :key_one)
      expect(graph).to have_received(graph_method_name).with(:key_one).once
    end
  end

  context 'with one key when the graph method returns an object' do
    before do
      allow(graph).to receive(graph_method_name).with(:key_one).and_return(:a)
    end

    it 'returns the result of the Graph call in an array' do
      result = described_class.public_send(method_name, graph, :key_one)
      expect(result).to eq(%i[a])
    end
  end

  context 'with one key when the graph method returns an array' do
    before do
      allow(graph).to receive(graph_method_name).with(:key_one).and_return(%i[a b])
    end

    it 'returns the result of the Graph call in an array' do
      result = described_class.public_send(method_name, graph, :key_one)
      expect(result).to eq(%i[a b])
    end
  end

  context 'with two keys' do
    before do
      allow(graph).to receive(graph_method_name).with(:key_one).and_return(%i[a b])
      allow(graph).to receive(graph_method_name).with(:key_two).and_return(%i[b c])
    end

    it 'calls the graph method twice' do
      described_class.public_send(method_name, graph, %i[key_one key_two])
      expect(graph).to have_received(graph_method_name).twice
    end

    it 'requests the first key' do
      described_class.public_send(method_name, graph, %i[key_one key_two])
      expect(graph).to have_received(graph_method_name).with(:key_one)
    end

    it 'requests the second key' do
      described_class.public_send(method_name, graph, %i[key_one key_two])
      expect(graph).to have_received(graph_method_name).with(:key_two)
    end

    it 'contains the result of both Graph calls' do
      result = described_class.public_send(method_name, graph, %i[key_one key_two])
      expect(result).to eq(%i[a b b c])
    end
  end

  context 'with two keys, one of which returns nil' do
    before do
      allow(graph).to receive(graph_method_name).with(:key_one).and_return(%i[a b])
      allow(graph).to receive(graph_method_name).with(:key_two).and_return(nil)
    end

    it 'removes the nil' do
      result = described_class.public_send(method_name, graph, %i[key_one key_two])
      expect(result).to eq(%i[a b])
    end
  end

  context 'with two keys, one of which returns an empty array' do
    before do
      allow(graph).to receive(graph_method_name).with(:key_one).and_return(%i[a b])
      allow(graph).to receive(graph_method_name).with(:key_two).and_return([])
    end

    it 'ignores the empty array' do
      result = described_class.public_send(method_name, graph, %i[key_one key_two])
      expect(result).to eq(%i[a b])
    end
  end
end

RSpec.describe Gql::QueryInterface::GraphHelper do
  let(:graph) { Qernel::Graph.new }

  describe '.carriers' do
    include_examples 'a delegated GraphHelper method' do
      let(:method_name) { :carriers }
      let(:graph_method_name) { :carrier }
    end
  end

  describe '.group_edges' do
    include_examples 'a delegated GraphHelper method' do
      let(:method_name) { :group_edges }
    end
  end

  describe '.group_nodes' do
    include_examples 'a delegated GraphHelper method' do
      let(:method_name) { :group_nodes }
    end
  end

  describe '.nodes' do
    include_examples 'a delegated GraphHelper method' do
      let(:method_name) { :nodes }
      let(:graph_method_name) { :node }
    end
  end

  describe '.sector_nodes' do
    include_examples 'a delegated GraphHelper method' do
      let(:method_name) { :sector_nodes }
    end
  end

  describe '.use_nodes' do
    include_examples 'a delegated GraphHelper method' do
      let(:method_name) { :use_nodes }
    end
  end
end
