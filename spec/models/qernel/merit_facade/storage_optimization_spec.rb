# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::MeritFacade::StorageOptimization do
  # Creates an adapter double with the given type, subtype, and load curve.
  def adapter_double(klass_name, type, subtype, curve: nil, adapter_klass: 'Qernel::MeritFacade::Adapter')
    adapter = instance_double(adapter_klass)
    participant = instance_double(klass_name)

    allow(participant).to receive(:load_curve).and_return(curve)

    allow(adapter).to receive(:config).and_return(
      Atlas::NodeAttributes::ElectricityMeritOrder.new(type: type, subtype: subtype)
    )

    allow(adapter).to receive(:participant).and_return(participant)

    adapter
  end

  def producer_double(subtype, curve)
    adapter_double('Merit::Producer', :producer, subtype, curve: curve)
  end

  def consumer_double(subtype, curve)
    adapter_double('Merit::User', :consumer, subtype, curve: curve)
  end

  def battery_double(key: nil, subtype: :optimizing_storage, volume:, capacity:, efficiency: 1.0)
    adapter = adapter_double(
      'Merit::CurveProducer',
      :flex,
      subtype,
      adapter_klass: 'Qernel::MeritFacade::OptimizingStorageAdapter'
    )

    node = instance_double('Qernel::Node')
    allow(node).to receive(:key).and_return(key)
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

  let(:opt) { described_class.new(adapters) }

  # ------------------------------------------------------------------------------------------------

  describe '#reserve_to_load' do
    context 'with [1, 2, 3, 2, 1, 0]' do
      it 'returns [-1, -1, -1, 1, 1, 1]' do
        expect(described_class.reserve_to_load([1, 2, 3, 2, 1, 0])).to eq([-1, -1, -1, 1, 1, 1])
      end
    end

    context 'with [1, 2, 1, 0], and an output efficiency of 0.75' do
      it 'returns [-1, -1, 0.75, 0.75]' do
        expect(
          described_class.reserve_to_load([1, 2, 1, 0], output_efficiency: 0.75)
        ).to eq([-1, -1, 0.75, 0.75])
      end
    end

    context 'with [1, 2, 1, 0] and an output efficiency of 0.1' do
      it 'returns [-0.5, -0.5, 0.1, 0.1]' do
        expect(
          described_class.reserve_to_load(
            [1, 2, 1, 0],
            output_efficiency: 0.1
          )
        ).to eq([-1, -1, 0.1, 0.1])
      end
    end

    context 'with [0, 0, 0, 0]' do
      it 'returns [0, 0, 0, 0]' do
        expect(described_class.reserve_to_load([0, 0, 0, 0])).to eq([0, 0, 0, 0])
      end
    end

    context 'with [1, 1, 0, 0]' do
      it 'returns [-1, 0, 1, 0]' do
        expect(described_class.reserve_to_load([1, 1, 0, 0])).to eq([-1, 0, 1, 0])
      end
    end
  end

  # ------------------------------------------------------------------------------------------------

  describe '#residual_load' do
    context 'with only accepted adapters' do
      let(:adapters) do
        [
          producer_double(:must_run, [1, 2, 3]),
          consumer_double(:volatile, [1, 5, 7]),
          consumer_double(nil, [1, 1, 1])
        ]
      end

      it 'computes the residual load curve' do
        expect(opt.residual_load.to_a.take(3)).to eq([1, 4, 5])
      end
    end

    context 'with a :pseudo subtype consumer' do
      let(:adapters) do
        [
          producer_double(:must_run, [1, 2, 3]),
          producer_double(:volatile, [1, 2, 3]),
          consumer_double(nil, [5, 5, 5]),
          consumer_double(:pseudo, [1, 1, 1])
        ]
      end

      it 'computes the residual load curve' do
        expect(opt.residual_load.to_a.take(3)).to eq([3, 1, -1])
      end
    end

    context 'with a :dispatchable subtype producer' do
      let(:adapters) do
        [
          producer_double(:must_run, [1, 2, 3]),
          producer_double(:volatile, [1, 2, 3]),
          producer_double(:dispatchable, [1, 2, 3]),
          consumer_double(nil, [5, 5, 5])
        ]
      end

      it 'computes the residual load curve' do
        expect(opt.residual_load.to_a.take(3)).to eq([3, 1, -1])
      end
    end

    context 'with a :flex type participant' do
      let(:adapters) do
        [
          producer_double(:must_run, [1, 2, 3]),
          producer_double(:volatile, [1, 2, 3]),
          consumer_double(nil, [5, 5, 5]),
          battery_double(subtype: :storage, volume: 0, capacity: 0)
        ]
      end

      it 'computes the residual load curve' do
        expect(opt.residual_load.to_a.take(3)).to eq([3, 1, -1])
      end
    end

    context 'with no consumers' do
      let(:adapters) do
        [
          producer_double(:must_run, [1, 2, 3]),
          producer_double(:volatile, [1, 2, 3])
        ]
      end

      it 'computes the residual load curve' do
        expect(opt.residual_load.to_a.take(3)).to eq([-2, -4, -6])
      end
    end

    context 'with no producers' do
      let(:adapters) do
        [
          consumer_double(nil, [1, 2, 3]),
          consumer_double(nil, [2, 3, 4])
        ]
      end

      it 'computes the residual load curve' do
        expect(opt.residual_load.to_a.take(3)).to eq([3, 5, 7])
      end
    end
  end

  describe '#reserve_for' do
    context 'with a single battery' do
      let(:adapters) do
        [
          consumer_double(:must_run, ([10_000.0] * 6 + [5000.0] * 6) * 365),
          battery_double(key: :a_battery, volume: 5000.0, capacity: 1000.0)
        ]
      end

      it 'calculates the battery reserve' do
        expect(opt.reserve_for(:a_battery)[24...36]).to eq([
          5000, 4000, 3000, 2000, 1000, 0, 0, 1000, 2000, 3000, 4000, 5000
        ])
      end

      it 'calculates the battery load' do
        expect(opt.load_for(:a_battery)[24...36]).to eq([
          0, 1000, 1000, 1000, 1000, 1000, 0, -1000, -1000, -1000, -1000, -1000
        ])
      end
    end

    context 'with a single battery with an output efficiency of 0.8' do
      let(:adapters) do
        [
          consumer_double(:must_run, (([15_000] * 5 + [30_000]) + ([5_000] * 6 )) * 365),
          battery_double(key: :a_battery, volume: 5000.0, capacity: 1000.0, efficiency: 0.8)
        ]
      end

      it 'calculates the battery reserve' do
        puts opt.reserve_for(:a_battery)[24...36]
        expect(opt.reserve_for(:a_battery)[24...36]).to eq([
          5000.0, 4250.0, 3500.0, 2750.0, 2000.0, 750.0, 1500.0, 2250.0, 3000.0, 3750.0, 4000.0, 5000.0
        ])
      end

      it 'calculates the battery load' do
        expect(opt.load_for(:a_battery)[24...36]).to eq([
          0.0, 600.0, 600.0, 600.0, 600.0, 1000.0, -750.0, -750.0, -750.0, -750.0, -250.0, -1000.0
        ])
      end
    end

    context 'with a single battery with an output efficiency of 1.2' do
      let(:adapters) do
        [
          consumer_double(:must_run, (([15_000] * 5 + [30_000]) + ([5_000] * 6 )) * 365),
          battery_double(key: :a_battery, volume: 5000.0, capacity: 1000.0, efficiency: 1.2)
        ]
      end

      it 'calculates the battery reserve' do
        puts opt.reserve_for(:a_battery)[24...36]
        expect(opt.reserve_for(:a_battery)[24...36].map(&:to_i)).to eq([
          833, 833, 833, 833, 833, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 833
        ])
      end

      it 'calculates the battery load' do
        expect(opt.load_for(:a_battery)[24...36].map(&:to_i)).to eq([
          0, 0, 0, 0, 0, 1000, 0, 0, 0, 0, 0, -833
        ])
      end
    end

    context 'with two batteries' do
      let(:adapters) do
        [
          consumer_double(:must_run, ([1000.0] * 6 + [500.0] * 6) * 365),
          battery_double(key: :first, volume: 500.0, capacity: 250.0),
          battery_double(key: :second, volume: 500.0, capacity: 100.0)
        ]
      end

      # The specific numbers in these tests are not important, and are dependent on the algorithm
      # (which is not being tested here). Rather, these tests seek to prove that the first and
      # second batteries charge and discharge in different hours depending on how the residual load
      # changes.

      # rubocop:disable RSpec/MultipleExpectations
      it 'calculates the second battery based on a new residual load curve' do
        first  = opt.reserve_for(:first)[24...36]
        second = opt.reserve_for(:second)[24...36]

        first_d  = first.map.with_index { |v, i| v <=> first[i - 1] }
        second_d = second.map.with_index { |v, i| v <=> second[i - 1] }

        # Assert that the two batteries charge and discharge in different hours.
        expect(second_d).not_to eq(first_d)

        # Assert that the batteries do something.
        expect(first_d.count(&:positive?)).to be_positive
        expect(first_d.count(&:negative?)).to be_positive

        expect(second_d.count(&:positive?)).to be_positive
        expect(second_d.count(&:negative?)).to be_positive

        # Assert that the second battery doesn't discharge when the first battery is charging.
        second_d.each.with_index do |v, i|
          expect(v).not_to eq(-first_d[i]) unless v.zero?
        end
      end
      # rubocop:enable RSpec/MultipleExpectations

      it 'does not re-sort the batteries' do
        expect(opt.send(:batteries).map { |b| b.node.key }).to eq(%i[first second])
      end
    end

    context 'with two batteries and a custom order' do
      let(:opt) { described_class.new(adapters, %i[second first]) }

      let(:adapters) do
        [
          consumer_double(:must_run, (([1000.0] * 6) + ([500.0] * 6)) * 365),
          battery_double(key: :first, volume: 500.0, capacity: 250.0),
          battery_double(key: :second, volume: 500.0, capacity: 100.0)
        ]
      end

      it 'sorts the batteries according to the order' do
        expect(opt.send(:batteries).map { |b| b.node.key }).to eq(%i[second first])
      end
    end
  end
end
