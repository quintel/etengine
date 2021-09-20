require 'spec_helper'

describe CostsParametersSerializer do
  let(:scenario) { FactoryBot.create(:scenario) }

  subject do
    CSV.parse(described_class.new(scenario).as_csv, headers: true)
  end

  it 'has 31 rows' do
    # 10 queries, 6 totals, 15 subtotals = 31 rows minimum (when no nodes in groups)
    expect(subject.length).to eq(31)
  end

  it 'has a row for each node' do
    expect(subject.first[0]).to eq('costs_building_and_installations')
  end
end
