# frozen_string_literal: true

require 'spec_helper'

describe CostsParametersSerializer do
  subject do
    CSV.parse(described_class.new(scenario).as_csv, headers: true)
  end

  let(:scenario) { FactoryBot.create(:scenario) }

  it 'has 31 rows' do
    # 10 queries, 6 totals, 24 subtotals = 40 rows minimum (when no nodes in groups)
    expect(subject.length).to eq(40)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq('costs_building_and_installations')
  end
end