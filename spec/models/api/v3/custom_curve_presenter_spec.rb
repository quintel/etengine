require 'spec_helper'

describe Api::V3::CustomCurvePresenter do
  let(:attachment) { FactoryBot.create(:scenario_attachment) }
  let(:json) { described_class.new(attachment).as_json }

  context 'with an attached curve' do
    before do
      attachment.custom_curve.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    it { expect(json).to include(name: 'price_curve.csv') }
    it { expect(json).to include(size: 35_040) }
    it { expect(json).to include(date: attachment.custom_curve.created_at) }
    it { expect(json[:stats]).to include(min: 1.0) }
    it { expect(json[:stats]).to include(min_at: 0) }
    it { expect(json[:stats]).to include(max: 2.0) }
    it { expect(json[:stats]).to include(max_at: 1) }
    it { expect(json[:stats]).to include(mean: 1.5) }
    it { expect(json[:stats]).to include(length: 8760) }
    it { expect(json[:other_scenario]).to eq({}) }

    context 'originating from another scenario' do
      before do
        attachment.update_attributes({
          other_scenario_id: 1,
          other_saved_scenario_id: 1,
          other_scenario_title: 'a',
          other_dataset_key: 'nl',
          other_end_year: 2050
        })
      end

       it { expect(json[:other_scenario]).to include(other_scenario_id: 1) }
       it { expect(json[:other_scenario]).to include(other_scenario_title: 'a') }
       it { expect(json[:other_scenario]).to include(other_saved_scenario_id: 1) }
       it { expect(json[:other_scenario]).to include(other_dataset_key: 'nl') }
       it { expect(json[:other_scenario]).to include(other_end_year: 2050) }
    end
  end

  context 'with no attached curve' do
    it { expect(json).to eq({}) }
  end
end
