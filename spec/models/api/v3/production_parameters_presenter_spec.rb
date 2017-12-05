require 'spec_helper'

describe Api::V3::ProductionParametersPresenter do
  let(:scenario) { FactoryBot.create(:scenario) }

  subject do
    CSV.parse(
      Api::V3::ProductionParametersPresenter.new(scenario).as_csv,
      headers: true
    )
  end

  it 'has one row' do
    expect(subject.length).to eq(1)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq('fd_electricity_for_merit_order')
  end
end
