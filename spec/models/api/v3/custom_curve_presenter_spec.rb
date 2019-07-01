require 'spec_helper'

describe Api::V3::CustomCurvePresenter do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:attachment) { scenario.imported_electricity_price_curve }
  let(:json) { described_class.new(attachment).as_json }

  context 'with an attached curve' do
    before do
      scenario.imported_electricity_price_curve.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/price_curve.csv')),
        filename: 'price_curve.csv',
        content_type: 'text/csv'
      )
    end

    it { expect(json).to include(name: 'price_curve.csv') }
    it { expect(json).to include(size: 35_040) }
    it { expect(json).to include(date: attachment.created_at) }
    it { expect(json[:stats]).to include(min: 1.0) }
    it { expect(json[:stats]).to include(min_at: 0) }
    it { expect(json[:stats]).to include(max: 2.0) }
    it { expect(json[:stats]).to include(max_at: 1) }
    it { expect(json[:stats]).to include(mean: 1.5) }
    it { expect(json[:stats]).to include(length: 8760) }
  end

  context 'with no attached curve' do
    it { expect(json).to eq({}) }
  end
end
