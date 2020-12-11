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

    it 'rounds each value to two decimal places' do
      expect(handler.sanitized_curve).to eq(curve.map { |v| v.round(2) })
    end
  end
end
