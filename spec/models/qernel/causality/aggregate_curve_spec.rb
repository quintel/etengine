require 'spec_helper'

describe Qernel::Causality::AggregateCurve do
  let(:dataset) { Atlas::Dataset.find(:nl) }
  let(:profile_one) { dataset.load_profile(:electric_vehicle_profile_1) }
  let(:profile_two) { dataset.load_profile(:electric_vehicle_profile_2) }

  let(:mix) { { profile_one => 0.5, profile_two => 0.5 } }
  let(:demand) { 1.0 }

  let(:curve) { described_class.build(mix) }

  describe 'with a 50/50 mix' do
    let(:mix) { { profile_one => 0.5, profile_two => 0.5 } }

    it 'contains data for each hour' do
      expect(curve.length).to eq(8760)
    end

    it 'creates a combined profile' do
      # ev1 = [1.0, 0.0, 1.0, 0.0, ...]
      # ev2 = [0.0, 1.0, 0.0, 1.0, ...]
      expect(curve.to_a.take(4).map { |v| v * 8760 })
        .to eq([1.0, 1.0, 1.0, 1.0])
    end

    it 'has a sum of 1.0' do
      expect(curve.to_a.sum).to be_within(1e-5).of(1.0)
    end
  end

  describe 'with a 75/25 mix' do
    let(:mix) { { profile_one => 0.75, profile_two => 0.25 } }

    it 'contains data for each hour' do
      expect(curve.length).to eq(8760)
    end

    it 'creates a combined profile' do
      expect(curve.to_a.take(4).map { |v| v * 8760 })
        .to eq([1.5, 0.5, 1.5, 0.5])
    end

    it 'has a sum of 1.0' do
      expect(curve.to_a.sum).to be_within(1e-5).of(1.0)
    end
  end

  describe 'with a 37.5/12.5 mix' do
    let(:mix) { { profile_one => 0.375, profile_two => 0.125 } }

    it 'contains data for each hour' do
      expect(curve.length).to eq(8760)
    end

    it 'creates a combined profile, balancing the mix' do
      expect(curve.to_a.take(4).map { |v| v * 8760 })
        .to eq([1.5, 0.5, 1.5, 0.5])
    end

    it 'has a sum of 1.0' do
      expect(curve.to_a.sum).to be_within(1e-5).of(1.0)
    end
  end

  describe 'with a 37.5 mix' do
    let(:mix) { { profile_one => 0.375 } }

    it 'contains data for each hour' do
      expect(curve.length).to eq(8760)
    end

    it 'creates a combined profile, balancing the mix' do
      expect(curve.to_a.take(4).map { |v| v * 8760 })
        .to eq([2.0, 0.0, 2.0, 0.0])
    end

    it 'has a sum of 1.0' do
      expect(curve.to_a.sum).to be_within(1e-5).of(1.0)
    end
  end

  describe 'with no profile components' do
    let(:mix) { {} }

    it 'contains data for each hour' do
      expect(curve.length).to eq(8760)
    end

    it 'has a sum of zero' do
      expect(curve.to_a.sum).to be_zero
    end
  end
end
