# frozen_string_literal: true

require 'spec_helper'
require_relative './shared_examples'

RSpec.describe CurveHandler::Processors::Profile do
  include_examples 'a CurveHandler processor'

  context 'with a curve containing 8760 floats' do
    let(:curve) { [1.0, 0.0] * 4380 }

    it 'normalizes the curve to 1 / 3600' do
      expect(handler.sanitized_curve.sum).to eq(1.0 / 3600)
    end

    it 'normalizes each individual value' do
      expect(handler.sanitized_curve.take(4)).to eq([1.0 / 4380 / 3600, 0.0] * 2)
    end
  end

  context 'with a curve containing only 0.0 floats' do
    let(:curve) { [0.0] * 8760 }

    it 'sets all curve values to zero' do
      expect(handler.sanitized_curve.sum).to eq(0)
    end

    it 'sets each value to zero' do
      expect(handler.sanitized_curve.take(4)).to eq([0.0, 0.0, 0.0, 0.0])
    end
  end
end
