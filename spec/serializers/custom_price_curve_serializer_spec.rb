# frozen_string_literal: true

require 'spec_helper'
require_relative './custom_curve_shared_examples'

describe Api::V3::CustomPriceCurveSerializer do
  let(:attachment) { FactoryBot.create(:scenario_attachment) }

  include_examples 'a custom curve Serializer'

  context 'with an attached curve' do
    let(:json) { described_class.new(attachment).as_json }

    before do
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    it { expect(json[:stats]).to include(min: 1.0) }
    it { expect(json[:stats]).to include(min_at: 0) }
    it { expect(json[:stats]).to include(max: 2.0) }
    it { expect(json[:stats]).to include(max_at: 1) }
    it { expect(json[:stats]).to include(mean: 1.5) }
    it { expect(json[:stats]).to include(length: 8760) }
    it { expect(json[:source_scenario]).to eq({}) }

    context 'when originating from another scenario' do
      let(:source) { FactoryBot.create(:scenario) }

      before do
        attachment.update(
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
