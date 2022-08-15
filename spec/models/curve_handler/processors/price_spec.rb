# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_examples'

RSpec.describe CurveHandler::Processors::Price do
  let(:handler) { described_class.new(curve) }

  include_examples 'a CurveHandler processor'
  include_examples 'a non-normalizing CurveHandler processor'

  context 'with a curve containing 8760 1.2345 floats' do
    let(:curve) { [1.2345] * 8760 }

    it 'is valid' do
      expect(handler).to be_valid
    end

    it 'keeps each value verbatim' do
      expect(handler.sanitized_curve).to eq(curve)
    end
  end

  context 'with a curve containing negatives' do
    let(:curve) { [0.0, -1.0, 1.0, 0.0] * 8760 }

    it 'is not valid' do
      expect(handler).not_to be_valid
    end
  end

  describe '.from_string' do
    let(:handler) { described_class.from_string(input) }

    context 'when given an exported price curve' do
      let(:input) do
        "Time,Price (Euros)\n" + ("N/A,1.2\n" * 8760)
      end

      it 'is valid' do
        expect(handler).to be_valid
      end

      it 'sanitizes the curve' do
        expect(handler.sanitized_curve).to eq([1.2] * 8760)
      end
    end

    context 'when given an exported price curve with malformed prices' do
      let(:input) do
        "Time,Price (Euros)\n" + ("N/A,1.2a\n" * 8760)
      end

      it 'is not valid' do
        expect(handler).not_to be_valid
      end
    end
  end
end
