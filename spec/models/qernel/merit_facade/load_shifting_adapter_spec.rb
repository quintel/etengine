require 'spec_helper'

RSpec.describe Qernel::MeritFacade::LoadShiftingAdapter, '#apply_deficit_limit and helpers' do
  subject(:adapter) { described_class.allocate }

  describe '#shift_out' do
    it 'returns 0.0 when cumulative >= max_deficit' do
      expect(adapter.send(:shift_out, 5.0, 10.0, 10.0)).to eq(0.0)
      expect(adapter.send(:shift_out, 5.0, 15.0, 10.0)).to eq(0.0)
    end

    it 'returns the minimum of value and remaining capacity when below limit' do
      expect(adapter.send(:shift_out, 5.0, 3.0, 10.0)).to eq(5.0)
      expect(adapter.send(:shift_out, 8.0, 3.0, 10.0)).to eq(7.0)
    end
  end

  describe '#recover' do
    it 'returns zero when there is no deficit to recover' do
      expect(adapter.send(:recover, 5.0, 0.0)).to eq(0.0)
    end

    it 'returns the lesser of deficit and recovery amount' do
      expect(adapter.send(:recover, 5.0, 10.0)).to eq(5.0)
      expect(adapter.send(:recover, 15.0, 10.0)).to eq(10.0)
    end
  end

  describe '#apply_deficit_limit' do
    it 'caps positive values when cumulative limit reached and allows recovery' do
      raw_curve = [1.0, 1.0, -1.0, 1.0, 1.0]
      max_deficit = 2.0

      input_curve, output_curve = adapter.send(:apply_deficit_limit, raw_curve, max_deficit)

      expect(output_curve).to eq([1.0, 1.0, 0.0, 1.0, 0.0])
      expect(input_curve).to  eq([0.0, 0.0, 1.0, 0.0, 0.0])
    end

    it 'treats max_deficit infinite when nil or zero' do
      raw_curve = [2.0, 2.0, -1.0, 2.0]
      infinite_inputs, infinite_outputs = adapter.send(:apply_deficit_limit, raw_curve, Float::INFINITY)
      expect(infinite_outputs).to eq([2.0, 2.0, 0.0, 2.0])
      expect(infinite_inputs).to  eq([0.0, 0.0, 1.0, 0.0])
    end
  end
end
