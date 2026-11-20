# frozen_string_literal: true

require 'spec_helper'

# Installed capacity which each type of adapter injects for the capacity data exports. Uses real
# Merit participants, so that a change in Merit or in an adapter breaks these examples.
RSpec.describe 'Installed capacity of Merit participants' do
  let(:node_api) { double('NodeApi') }
  let(:context) { double('Context', carrier: :electricity) }
  let(:config) { double('Config', delegate: nil, group: nil) }

  let(:producer) do
    Merit::DispatchableProducer.new(
      key: :producer, marginal_costs: 1.0, output_capacity_per_unit: 3.0, number_of_units: 4.0,
      availability: 0.9
    )
  end

  let(:flex) do
    Merit::Flex::Base.new(
      key: :flex, marginal_costs: 1.0, input_capacity_per_unit: 5.0, output_capacity_per_unit: 2.0,
      number_of_units: 10.0, availability: 0.25
    )
  end

  def build_adapter(klass, participant = nil, **ivars)
    klass.allocate.tap do |adapter|
      { participant:, config:, context:, node: node_api, **ivars }.each do |name, value|
        adapter.instance_variable_set(:"@#{name}", value)
      end
    end
  end

  def capacity(adapter, direction)
    if direction == :input
      adapter.send(:installed_input_capacity)
    elsif direction == :output
      adapter.send(:installed_output_capacity)
    end
  end

  def load_curve(values)
    Merit::Curve.new(values + ([0.0] * (8760 - values.length)))
  end

  describe 'injecting' do
    it 'sets the capacity per direction on the node' do
      expect(node_api).to receive(:dataset_set).with(:electricity_input_installed_capacity, nil)
      expect(node_api).to receive(:dataset_set).with(:electricity_output_installed_capacity, 12.0)

      build_adapter(Qernel::MeritFacade::DispatchableAdapter, producer).inject_installed_capacity!
    end
  end

  describe 'a producer (dispatchable, must-run, volatile)' do
    let(:adapter) { build_adapter(Qernel::MeritFacade::DispatchableAdapter, producer) }

    it 'has an output capacity per unit x number of units, without availability' do
      expect(capacity(adapter, :output)).to eq(12.0)
    end

    it 'has no input capacity' do
      expect(capacity(adapter, :input)).to be_nil
    end
  end

  describe 'a backup (shortage)' do
    let(:adapter) { build_adapter(Qernel::MeritFacade::BackupAdapter, producer) }

    it 'is sized to the largest shortage it covered' do
      allow(producer).to receive(:load_curve).and_return(load_curve([1.0, 7.0, 3.0]))
      expect(capacity(adapter, :output)).to eq(7.0)
    end
  end

  describe 'a flexible producer and consumer' do
    let(:adapter) { build_adapter(Qernel::MeritFacade::StorageAdapter, flex) }

    it 'has an input capacity per unit x number of units' do
      expect(capacity(adapter, :input)).to eq(50.0)
    end

    it 'has an output capacity per unit x number of units' do
      expect(capacity(adapter, :output)).to eq(20.0)
    end

    context 'with units of all electric vehicles (a delegate)' do
      let(:config) { double('Config', delegate: :transport_car_using_electricity, group: nil) }

      it 'only counts the share taking part in vehicle-to-grid' do
        expect(capacity(adapter, :input)).to eq(12.5)
      end
    end
  end

  describe 'load shifting' do
    let(:adapter) do
      build_adapter(Qernel::MeritFacade::LoadShiftingAdapter, [flex, double('Inflexible')])
    end

    it 'has the capacity of its main participant' do
      expect(capacity(adapter, :output)).to eq(20.0)
    end
  end

  describe 'curtailment (excess)' do
    let(:adapter) { build_adapter(Qernel::MeritFacade::CurtailmentAdapter, flex) }

    before { allow(flex).to receive(:load_curve).and_return(load_curve([-3.0, -8.0, 0.0])) }

    it 'has the largest excess it took as input capacity' do
      expect(capacity(adapter, :input)).to eq(8.0)
    end

    it 'has no output capacity' do
      expect(capacity(adapter, :output)).to eq(0.0)
    end
  end

  describe 'infinite heat storage' do
    let(:config) { double('Config', delegate: nil, group: :infinite) }
    let(:adapter) { build_adapter(Qernel::MeritFacade::HeatStorageAdapter, flex) }

    before { allow(flex).to receive(:load_curve).and_return(load_curve([-3.0, -8.0, 4.0])) }

    it 'has the largest excess it stored as input capacity' do
      expect(capacity(adapter, :input)).to eq(8.0)
    end

    it 'has an output capacity per unit x number of units' do
      expect(capacity(adapter, :output)).to eq(20.0)
    end
  end

  describe 'optimizing storage' do
    let(:adapter) { build_adapter(Qernel::MeritFacade::OptimizingStorageAdapter) }

    before do
      allow(adapter).to receive(:optimizing_storage_params).and_return(
        Qernel::MeritFacade::OptimizingStorageAdapter::Params.new(
          input_capacity: 5.0, output_capacity: 4.0, volume: 1.0, output_efficiency: 1.0
        )
      )
    end

    it 'has the limits of the storage optimization' do
      expect([capacity(adapter, :input), capacity(adapter, :output)]).to eq([5.0, 4.0])
    end
  end

  describe 'a transformation' do
    it 'only has the output capacity of its producing side' do
      adapter = build_adapter(Qernel::MeritFacade::TransformationAdapter, producer_participant: producer)
      expect([capacity(adapter, :input), capacity(adapter, :output)]).to eq([nil, 12.0])
    end

    it 'has no capacity without producing side' do
      adapter = build_adapter(Qernel::MeritFacade::TransformationAdapter)
      expect(capacity(adapter, :output)).to be_nil
    end
  end

  describe 'a consumer (must-run)' do
    it 'has no capacity in Merit' do
      adapter = build_adapter(Qernel::MeritFacade::ConsumerAdapter)
      expect([capacity(adapter, :input), capacity(adapter, :output)]).to eq([nil, nil])
    end
  end
end
