# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Causality::LazyCurve do
  let(:curve) do
    described_class.new { |frame| frame }
  end

  it 'can fetch values with get' do
    expect(curve.get(5)).to eq(5)
  end

  it 'can fetch values with []' do
    expect(curve[5]).to eq(5)
  end

  it 'returns self when calling values' do
    expect(curve.values).to eq(curve)
  end

  context 'when calling the first two values' do
    let!(:first) { curve.get(0) }
    let!(:second) { curve.get(1) }

    it 'returns the value for the first frame' do
      expect(first).to eq(0)
    end

    it 'returns the value for the second frame' do
      expect(second).to eq(1)
    end

    it 'can be summed' do
      expect(curve.sum).to eq((1..8759).sum)
    end

    describe '#to_a' do
      subject { curve.to_a }

      it 'is an array' do
        expect(subject).to be_a(Array)
      end

      it 'has 8760 elements' do
        expect(subject.length).to eq(8760)
      end

      it 'has the called values' do
        expect(subject[0..1]).to eq([0, 1])
      end

      it 'populates any uncalled values' do
        expect(subject[2..]).to eq((2..8759).to_a)
      end

      it 'returns a different object each time' do
        expect(subject.object_id).not_to eq(curve.to_a.object_id)
      end
    end
  end

  context 'when calling the all values' do
    before do
      8760.times { |frame| curve.get(frame) }
    end

    it 'can be summed' do
      expect(curve.sum).to eq((1..8759).sum)
    end

    describe '#to_a' do
      subject { curve.to_a }

      it 'is an array' do
        expect(subject).to be_a(Array)
      end

      it 'has 8760 elements' do
        expect(subject.length).to eq(8760)
      end

      it 'has the called values' do
        expect(subject).to eq((0..8759).to_a)
      end

      it 'returns a different object each time' do
        expect(subject.object_id).not_to eq(curve.to_a.object_id)
      end
    end
  end

  context 'when calling a value beyond index 8759' do
    before do
      8760.times { |frame| curve.get(frame) }
    end

    let!(:extra_value) { curve.get(8760) }

    it 'returns the extra value' do
      expect(extra_value).to eq(8760)
    end

    it 'can be summed' do
      expect(curve.sum).to eq((1..8759).sum)
    end

    describe '#to_a' do
      subject { curve.to_a }

      it 'is an array' do
        expect(subject).to be_a(Array)
      end

      it 'has 8760 elements' do
        expect(subject.length).to eq(8760)
      end

      it 'has the called values' do
        expect(subject).to eq((0..8759).to_a)
      end

      it 'returns a different object each time' do
        expect(subject.object_id).not_to eq(curve.to_a.object_id)
      end
    end
  end
end
