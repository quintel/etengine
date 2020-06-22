require 'spec_helper'

describe Api::V3::NodeFlowPresenter do
  let(:scenario) { FactoryBot.create(:scenario) }

  subject do
    CSV.parse(
      Api::V3::NodeFlowPresenter.new(scenario).as_csv,
      headers: true
    )
  end

  it 'has one row for each node' do
    expect(subject.length).to eq(Atlas::Node.all.length)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq(Atlas::Node.all.map(&:key).sort.first.to_s)
  end
end
