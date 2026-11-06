# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::Capacity do
  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:plant, demand: 100, typical_input_capacity: 2.0, number_of_units: 10.0)
      builder.add(:sink, demand: 50)
      builder.add(:loss, demand: 50)
      builder.connect(:fuel, :plant, :natural_gas)
      builder.connect(:plant, :sink, :electricity)
      builder.connect(:plant, :loss, :loss)
    end
  end

  let(:graph) { builder.to_qernel }
  let(:node) { graph.node(:plant) }
  let(:plugin) { nil }

  before do
    # Test graphs don't assign themselves to their nodes.
    allow(node).to receive(:graph).and_return(graph)
    allow(graph).to receive(:plugin).with(:time_resolve).and_return(plugin)
  end

  def query(method)
    node.node_api.public_send(method)
  end

  def merit_config(type, subtype = :generic)
    Atlas::NodeAttributes::MeritOrder.new(type:, subtype:)
  end

  it 'defines a method per carrier and direction' do
    expect(Qernel::NodeApi::Base.public_method_defined?(:steam_hot_water_input_installed_capacity))
      .to be(true)
  end

  context 'without a Merit participant' do
    it 'is the typical input capacity × conversion × number of units' do
      # 2.0 MW × 0.5 × 10 units
      expect(query(:electricity_output_installed_capacity)).to eq(10.0)
    end

    it 'falls back to the peak of the curve without input capacity' do
      node.node_api.dataset_set(:typical_input_capacity, 0.0)
      node.node_api.dataset_set(:electricity_output_curve, [1.0, 7.0, 3.0])

      expect(query(:electricity_output_installed_capacity)).to eq(7.0)
    end

    it 'is 0 without input capacity and curve' do
      node.node_api.dataset_set(:typical_input_capacity, 0.0)
      expect(query(:electricity_output_installed_capacity)).to eq(0.0)
    end
  end

  context 'with a network gas participant using another demand carrier' do
    before do
      node.node_api.dataset_set(
        :network_gas,
        Atlas::NodeAttributes::Reconciliation.new(type: :consumer, demand_carrier: :natural_gas)
      )
    end

    it 'uses the conversion of the demand carrier' do
      # natural gas input conversion is 1.0
      expect(query(:network_gas_input_installed_capacity)).to eq(20.0)
    end
  end

  context 'with a backup in any merit order' do
    before do
      node.node_api.dataset_set(:heat_network_ht, merit_config(:producer, :backup))
      node.node_api.dataset_set(:electricity_output_curve, [1.0, 9.0])
    end

    it 'uses the peak for all carriers' do
      expect(query(:electricity_output_installed_capacity)).to eq(9.0)
    end
  end

  context 'with a Merit participant' do
    let(:participant) do
      instance_double(Merit::DispatchableProducer, output_capacity_per_unit: 3.0, number_of_units: 4.0)
    end
    let(:adapter) do
      instance_double(Qernel::MeritFacade::DispatchableAdapter, installed?: true, participant:)
    end
    let(:plugin) do
      instance_double(
        Qernel::Plugins::Causality,
        merit: instance_double(Qernel::Causality::Electricity, adapters: { plant: adapter })
      )
    end

    before do
      node.node_api.dataset_set(:merit_order, merit_config(:producer, :dispatchable))
      node.node_api.dataset_set(:electricity_output_curve, [1.0, 200.0])
    end

    it 'uses the capacity of the participant' do
      expect(query(:electricity_output_installed_capacity)).to eq(12.0)
    end

    it 'is 0 when the participant is not in the merit order' do
      allow(adapter).to receive(:installed?).and_return(false)
      expect(query(:electricity_output_installed_capacity)).to eq(0.0)
    end

    it 'uses the first of several participants (load shifting)' do
      allow(adapter).to receive(:participant).and_return([participant, double])
      expect(query(:electricity_output_installed_capacity)).to eq(12.0)
    end

    it 'falls back to the peak for unlimited capacity' do
      allow(participant).to receive(:output_capacity_per_unit).and_return(Float::INFINITY)
      expect(query(:electricity_output_installed_capacity)).to eq(200.0)
    end

    it 'falls back to the peak for the ETSource 1e15 sentinel' do
      allow(participant).to receive(:output_capacity_per_unit).and_return(1e15)
      expect(query(:electricity_output_installed_capacity)).to eq(200.0)
    end
  end

  context 'with an optimizing storage participant' do
    let(:adapter) do
      instance_double(
        Qernel::MeritFacade::OptimizingStorageAdapter,
        installed?: true,
        optimizing_storage_params: Qernel::MeritFacade::OptimizingStorageAdapter::Params.new(
          input_capacity: 5.0, output_capacity: 4.0, volume: 1.0, output_efficiency: 1.0
        )
      )
    end
    let(:plugin) do
      instance_double(
        Qernel::Plugins::Causality,
        merit: instance_double(Qernel::Causality::Electricity, adapters: { plant: adapter })
      )
    end

    before { node.node_api.dataset_set(:merit_order, merit_config(:flex, :optimizing_storage)) }

    it 'uses the capacities of the storage optimization' do
      expect(query(:electricity_input_installed_capacity)).to eq(5.0)
      expect(query(:electricity_output_installed_capacity)).to eq(4.0)
    end
  end
end
