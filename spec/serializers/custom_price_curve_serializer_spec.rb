# frozen_string_literal: true

require 'spec_helper'
require_relative './custom_curve_shared_examples'

RSpec.describe CustomPriceCurveSerializer do
  let(:curve_data) { [1.0, 2.0] + [0.0] * (8760 - 2) }

  let(:curve) do
    FactoryBot.create(:user_curve).tap do |uc|
      uc.curve = Merit::Curve.new(curve_data)
      uc.save!
    end
  end

  include_examples 'a custom curve Serializer'

  describe 'with a stored curve' do
    let(:json) { described_class.new(curve).as_json }

    it { expect(json[:stats]).to include(min: 0.0) }
    it { expect(json[:stats]).to include(min_at: 2) }
    it { expect(json[:stats]).to include(max: 2.0) }
    it { expect(json[:stats]).to include(max_at: 1) }
    it { expect(json[:stats]).to include(mean: curve_data.sum / curve_data.length) }
    it { expect(json[:stats]).to include(length: 8760) }
    it { expect(json[:source_scenario]).to eq({}) }

    context 'when originating from another scenario' do
      let(:source) { FactoryBot.create(:scenario) }

      before do
        curve.update!(
          source_scenario_id: source.id,
          source_saved_scenario_id: 1,
          source_scenario_title: 'a',
          source_dataset_key: 'nl',
          source_end_year: 2050
        )
      end

      it 'includes the source scenario ID' do
        expect(json[:source_scenario]).to include(source_scenario_id: source.id)
      end

      it 'includes the source scenario title' do
        expect(json[:source_scenario]).to include(source_scenario_title: 'a')
      end

      it 'includes the saved scenario ID' do
        expect(json[:source_scenario]).to include(source_saved_scenario_id: 1)
      end

      it { expect(json[:source_scenario]).to include(source_dataset_key: 'nl') }
      it { expect(json[:source_scenario]).to include(source_end_year: 2050) }
    end
  end
end
