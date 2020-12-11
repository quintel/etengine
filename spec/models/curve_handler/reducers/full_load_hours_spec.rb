# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurveHandler::Reducers::FullLoadHours do
  let(:processor) { Struct.new(:sanitized_curve).new(curve) }
  let(:result) { described_class.call(processor) }

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

  context 'when given [0, 0, 0, 0]' do
    let(:curve) { [0.0, 0.0, 0.0, 0.0] }

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
