require 'spec_helper'

describe Api::V3::ConverterFlowPresenter do
  let(:scenario) { FactoryGirl.create(:scenario) }

  subject do
    CSV.parse(
      Api::V3::ConverterFlowPresenter.new(scenario).as_csv,
      headers: true
    )
  end

  it 'has one row for each converter' do
    expect(subject.length).to eq(Atlas::Node.all.length)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq(Atlas::Node.all.map(&:key).sort.first.to_s)
  end
end
