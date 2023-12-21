# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::MeritFacade::StorageOptimizationDistribution do
  # Creates an adapter double with the given type, subtype, and load curve.
  def adapter_double(klass_name, type, subtype, curve: nil, adapter_klass: 'Qernel::MeritFacade::Adapter', sector: :households)
    adapter = instance_double(adapter_klass)
    participant = instance_double(klass_name)

    allow(participant).to receive(:load_curve).and_return(curve)

    allow(adapter).to receive(:config).and_return(
      Atlas::NodeAttributes::ElectricityMeritOrder.new(type: type, subtype: subtype)
    )

    allow(adapter).to receive(:participant).and_return(participant)

    node = instance_double('Qernel::Node')
    allow(node).to receive(:sector_key).and_return(sector)
    allow(adapter).to receive(:node).and_return(node)

    adapter
  end

  def producer_double(subtype, curve)
    adapter_double('Merit::Producer', :producer, subtype, curve: curve)
  end

  def consumer_double(subtype, curve, sector: :households)
    adapter_double('Merit::User', :consumer, subtype, curve: curve, sector: sector)
  end

  def battery_double(key: nil, subtype: :optimizing_storage, volume:, capacity:, efficiency: 1.0, sector: :households)
    adapter = adapter_double(
      'Merit::CurveProducer',
      :flex,
      subtype,
      adapter_klass: 'Qernel::MeritFacade::OptimizingStorageAdapter'
    )

    node = instance_double('Qernel::Node')
    allow(node).to receive(:key).and_return(key)
    allow(node).to receive(:sector_key).and_return(sector)
    allow(adapter).to receive(:node).and_return(node)

    params = Qernel::MeritFacade::OptimizingStorageAdapter::Params.new(
      input_capacity: capacity,
      output_capacity: capacity,
      volume: volume,
      output_efficiency: efficiency
    )

    allow(adapter).to receive(:optimizing_storage_params).and_return(params)

    adapter
  end

  let(:opt_dist) { described_class.new(adapters) }

  describe '#reserve_for' do
    context 'with a single battery targeted towards the full system' do
      let(:adapters) do
        [
          consumer_double(:must_run, ([10_000.0] * 6 + [5000.0] * 6) * 365),
          battery_double(key: :a_battery, volume: 5000.0, capacity: 1000.0)
        ]
      end

      it 'calculates the battery reserve' do
        expect(opt_dist.reserve_for(:a_battery)[24...36]).to eq([
          5000, 4000, 3000, 2000, 1000, 0, 0, 1000, 2000, 3000, 4000, 5000
        ])
      end

      it 'calculates the battery load' do
        expect(opt_dist.load_for(:a_battery)[24...36]).to eq([
          0, 1000, 1000, 1000, 1000, 1000, 0, -1000, -1000, -1000, -1000, -1000
        ])
      end
    end

    context 'with a single battery targeted towards the households sector' do
      let(:adapters) do
        [
          consumer_double(:must_run, ([10_000.0] * 6 + [5000.0] * 6) * 365),
          battery_double(key: :a_battery, volume: 5000.0, capacity: 1000.0, subtype: :optimizing_storage_households)
        ]
      end

      it 'calculates the battery reserve' do
        expect(opt_dist.reserve_for(:a_battery)[24...36]).to eq([
          5000, 4000, 3000, 2000, 1000, 0, 0, 1000, 2000, 3000, 4000, 5000
        ])
      end

      it 'calculates the battery load' do
        expect(opt_dist.load_for(:a_battery)[24...36]).to eq([
          0, 1000, 1000, 1000, 1000, 1000, 0, -1000, -1000, -1000, -1000, -1000
        ])
      end
    end

    context 'with one battery targeted towards the households sector, and one towards system' do
      let(:adapters) do
        [
          consumer_double(:must_run, ([10_000.0] * 6 + [5000.0] * 6) * 365),
          consumer_double(:must_run, ([10_000.0] * 6 + [5000.0] * 6) * 365, sector: :industry),
          battery_double(key: :hh_battery, volume: 5000.0, capacity: 1000.0, subtype: :optimizing_storage_households),
          battery_double(key: :system_battery, volume: 5000.0, capacity: 1000.0)
        ]
      end

      it 'calculates the households battery reserve' do
        expect(opt_dist.reserve_for(:hh_battery)[24...36]).to eq([
          5000, 4000, 3000, 2000, 1000, 0, 0, 1000, 2000, 3000, 4000, 5000
        ])
      end

      it 'calculates the households battery load' do
        expect(opt_dist.load_for(:hh_battery)[24...36]).to eq([
          0, 1000, 1000, 1000, 1000, 1000, 0, -1000, -1000, -1000, -1000, -1000
        ])
      end

      it 'calculates the systems battery reserve' do
        expect(opt_dist.reserve_for(:system_battery)[24...36]).to eq([
          5000, 4000, 3000, 2000, 1000, 0, 0, 1000, 2000, 3000, 4000, 5000
        ])
      end

      it 'calculates the systems battery load' do
        expect(opt_dist.load_for(:system_battery)[24...36]).to eq([
          0, 1000, 1000, 1000, 1000, 1000, 0, -1000, -1000, -1000, -1000, -1000
        ])
      end
    end
  end
end
