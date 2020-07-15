# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::NodeFlowPresenter do
  subject do
    CSV.parse(
      described_class.new(scenario).as_csv,
      headers: true
    )
  end

  let(:scenario) { FactoryBot.create(:scenario) }

  it 'has one row for each node' do
    expect(subject.length).to eq(Atlas::EnergyNode.all.length)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq(Atlas::EnergyNode.all.map(&:key).min.to_s)
  end
end
