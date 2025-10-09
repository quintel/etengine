require 'spec_helper'

describe Gql::Gql do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'ameland') }
  let(:gql) { Gql::Gql.new(scenario) }

  context 'with a scalar input' do
    before do
      scenario.user_values = { foo_demand: 10.0 }
      gql.prepare
    end

    it 'updates the future graph with the input value' do
      expect(gql.future.graph.node(:foo).preset_demand).to eq(10.0)
    end
  end

  context 'with a % input' do
    before do
      scenario.user_values = { foo_demand_percent: 5.0 }
      gql.prepare
    end

    it 'updates the future graph with the input value' do
      base = gql.present.graph.node(:foo).demand
      expect(gql.future.graph.node(:foo).preset_demand).to eq(base * 1.05)
    end
  end

  context 'with a %y input' do
    before do
      scenario.user_values = { foo_demand_ypercent: 1.0 }
      gql.prepare
    end

    it 'updates the future graph with the input value' do
      # Apply an annual growth rate to the base (present) demand.
      years = scenario.end_year - scenario.start_year
      base  = gql.present.graph.node(:foo).demand
      expect(gql.future.graph.node(:foo).preset_demand)
        .to be_within(1e-9).of(base * (1.01**years))
    end
  end
end
