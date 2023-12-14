# frozen_string_literal: true

require 'spec_helper'

describe CostsParametersSerializer do
  subject do
    CSV.parse(described_class.new(scenario).as_csv, headers: true)
  end

  let(:scenario) { FactoryBot.create(:scenario) }

  it 'has 40 rows' do
    # 12 queries, 6 totals, 24 subtotals = 42 rows minimum (when no nodes in groups)
    expect(subject.length).to eq(44)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq('costs_building_and_installations')
  end
end
