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

  describe "with incorrect initial inputs" do
    before do
      gql.prepare
      gql.present.graph.area.stub(:init).
        and_return({non_existing_initializer_input: 5})
    end

    it 'raises an error' do
      expect { gql.prepare }.to raise_error(KeyError)
    end
  end
end
