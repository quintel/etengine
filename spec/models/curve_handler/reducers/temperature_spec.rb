# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurveHandler::Reducers::Temperature do
  let(:result) { described_class.call(curve, original) }

  context 'when the original curve is [1, 1, 1, 1]' do
    let(:original) { [1.0, 1.0, 1.0, 1.0] }

    context 'when given [1, 1, 1, 1]' do
      let(:curve) { [1.0, 1.0, 1.0, 1.0] }

      it 'returns 0' do
        expect(result).to eq(0)
      end
    end

    context 'when given [0, 0, 0, 0]' do
      let(:curve) { [0.0, 0.0, 0.0, 0.0] }

      it 'returns -1' do
        expect(result).to eq(-1)
      end
    end

    context 'when given [20, 20, 20, 20]' do
      let(:curve) { [20.0, 20.0, 20.0, 20.0] }

      it 'returns 19' do
        expect(result).to eq(19)
      end
    end

    context 'when given [20, 1, 20, 1]' do
      let(:curve) { [20.0, 1.0, 20.0, 1.0] }

      it 'returns 9.5' do
        expect(result).to eq(9.5)
      end
    end
  end
end
