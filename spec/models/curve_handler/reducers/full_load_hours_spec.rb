# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurveHandler::Reducers::FullLoadHours do
  let(:result) { described_class.call(curve) }

  context 'when given [1, 1, 1, 1]' do
    let(:curve) { [1.0, 1.0, 1.0, 1.0] }

    it 'returns 8760' do
      expect(result).to eq(8760)
    end
  end

  context 'when given [1, 1, ... 1, 1] (length = 8760)' do
    let(:curve) { [1.0] * 8760 }

    it 'returns 8760' do
      expect(result).to eq(8760)
    end
  end

  context 'when given [1, 1, ... 1, 1] (length = 17520)' do
    let(:curve) { [1.0] * 17_520 }

    it 'returns 8760' do
      expect(result).to eq(8760)
    end
  end

  context 'when given [1, 0, 1, 0]' do
    let(:curve) { [1.0, 0.0, 1.0, 0.0] }

    it 'returns 4380' do
      expect(result).to eq(4380)
    end
  end

  context 'when given [0.5, 0.5, 0.5, 0.5]' do
    let(:curve) { [0.5, 0.5, 0.5, 0.5] }

    it 'returns 4380' do
      expect(result).to eq(4380)
    end
  end

  context 'when given [0, 0, 0, 0]' do
    let(:curve) { [0.0, 0.0, 0.0, 0.0] }

    it 'returns 0' do
      expect(result).to eq(0)
    end
  end

  context 'when given [2, 2, 2, 2]' do
    let(:curve) { [2.0, 2.0, 2.0, 2.0] }

    it 'returns 8760' do
      expect(result).to eq(8760)
    end
  end

  context 'when given [-1, -1, -1, -1]' do
    let(:curve) { [-1.0, -1.0, -1.0, -1.0] }

    it 'returns 0' do
      expect(result).to eq(0)
    end
  end

  context 'when given []' do
    let(:curve) { [] }

    it 'returns 0' do
      expect(result).to eq(0)
    end
  end
end
