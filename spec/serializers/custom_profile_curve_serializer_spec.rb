# frozen_string_literal: true

require 'spec_helper'
require_relative './custom_curve_shared_examples'

RSpec.describe CustomProfileCurveSerializer do
  let(:curve) { FactoryBot.create(:user_curve) }

  include_examples 'a custom curve Serializer'

  context 'with a curve that has a "reduce" config' do
    let(:json) { described_class.new(curve).as_json }

    before do
      allow(CurveHandler::Config).to receive(:find).and_return(
        CurveHandler::Config.new(
          :interconnector_1_price,
          :capacity_profile,
          :full_load_hours,
          %w[input_one]
        )
      )
    end

    it 'includes full_load_hours in the stats' do
      expect(json[:stats]).to include(:full_load_hours)
      expect(json[:stats][:length]).to eq(8760)
    end
  end

  context 'with a curve that does not have a "reduce" config' do
    let(:json) { described_class.new(curve).as_json }

    before do
      allow(CurveHandler::Config).to receive(:find).and_return(
        CurveHandler::Config.new(
          :interconnector_1_price,
          :profile,
          nil,
          []
        )
      )
    end

    it 'does not include full_load_hours in the stats' do
      expect(json[:stats]).not_to have_key(:full_load_hours)
    end
  end
end
