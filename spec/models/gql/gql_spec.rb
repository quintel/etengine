require 'spec_helper'

describe Gql::Gql do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'ameland') }
  let(:gql) { Gql::Gql.new(scenario) }

  describe "with correct initial inputs" do
    before { gql.prepare }

    # Setting the demand of foo to 50.0
    it 'updates the present graph with initializer inputs' do
      expect(gql.present.graph.node(:foo).demand).to eq(50.0)
    end

    it 'updates the future graph with initializer inputs' do
      expect(gql.future.graph.node(:foo).demand).to eq(50.0)
    end

    # Setting the demand of baz to 50.0
    it 'updates the present graph with initializer inputs' do
      expect(gql.present.graph.node(:baz).demand).to eq(50.0)
    end

    it 'updates the future graph with initializer inputs' do
      expect(gql.future.graph.node(:baz).demand).to eq(50.0)
    end
  end

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
      expect(gql.future.graph.node(:foo).preset_demand).to eq(50.0 * 1.05)
    end
  end

  context 'with a %y input' do
    before do
      scenario.user_values = { foo_demand_ypercent: 1.0 }
      gql.prepare
    end

    it 'updates the future graph with the input value' do
      # future year (2040) - present year (2011) = 29
      expect(gql.future.graph.node(:foo).preset_demand)
        .to be_within(1e-9).of(50 * (1.01**29))
    end
  end

  describe 'use_network_calculations' do
    it 'is unchanged for unscaled scenarios' do
      gql.prepare
      expect(gql.future.graph.area.use_network_calculations).to eql(true)
    end

    it 'is false for scaled scenarios' do
      scenario.build_scaler(base_value: 1000, value: 10)
      gql.prepare
      expect(gql.future.graph.area.use_network_calculations).to eql(false)
    end
  end
end
