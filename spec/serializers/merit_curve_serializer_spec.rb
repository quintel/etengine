# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MeritCurveSerializer do
  let(:raw_values) { [1.0, 2.0, 3.0] }
  let(:length)     { 5 }
  let(:default)    { 0.0 }

  let(:curve) { Merit::Curve.new(raw_values, length, default) }

  describe '.dump and .load' do
    it 'serializes and deserializes a Merit::Curve with correct values' do
      packed = described_class.dump(curve)
      unpacked = described_class.load(packed)

      expect(unpacked).to be_a(Merit::Curve)
      expect(unpacked.to_a).to eq([1.0, 2.0, 3.0, 0.0, 0.0])
    end

    it 'preserves length and default values' do
      unpacked = described_class.load(described_class.dump(curve))

      expect(unpacked.length).to eq(length)
      expect(unpacked.instance_variable_get(:@default)).to eq(default)
    end

    it 'handles an empty curve' do
      empty = Merit::Curve.new([], 4, 0.5)
      unpacked = described_class.load(described_class.dump(empty))

      expect(unpacked.to_a).to eq([0.5, 0.5, 0.5, 0.5])
    end

    it 'handles a curve with no specified length' do
      curve = Merit::Curve.new([1.0, 2.0])
      unpacked = described_class.load(described_class.dump(curve))

      expect(unpacked.to_a).to eq([1.0, 2.0])
    end
  end

  describe 'integration with UserCurve factory' do
    let(:user_curve) { create(:user_curve, key: 'custom_curve') }

    it 'stores and retrieves a Merit::Curve via the model' do
      reloaded = UserCurve.find(user_curve.id)

      expect(reloaded.curve).to be_a(Merit::Curve)
      expect(reloaded.curve.to_a).to eq(user_curve.curve.to_a)
    end
  end
end
