require 'spec_helper'

describe Gql::Gql do
  let(:scenario) { FactoryGirl.create(:scenario, area_code: 'ameland') }
  let(:gql) { Gql::Gql.new(scenario) }

  describe "with correct initial inputs" do
    before { gql.prepare }

    it 'updates the present graph with initializer inputs' do
      expect(gql.present.graph.converter(:foo).demand).to eq(50.0)
    end

    it 'updates the future graph with initializer inputs' do
      expect(gql.future.graph.converter(:foo).demand).to eq(50.0)
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
