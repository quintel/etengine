# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/RepeatedExampleGroupBody
describe Gql::Runtime::Functions::Update, :etsource_fixture do
  let(:gql) { Scenario.default.gql(prepare: true) }
  let(:graph) { gql.future.graph }

  let(:result) do |example|
    gql.query_future(example.metadata[:example_group][:description])
  end

  # UPDATE
  # ----

  describe 'UPDATE(V(bar), demand, 10)' do
    before { result }

    it 'sets the node demand to 10' do
      expect(graph.node(:bar).demand).to eq(10)
    end
  end

  describe 'UPDATE(V(bar, baz), demand, 10)' do
    before { result }

    it 'sets the "bar" node demand to 10' do
      expect(graph.node(:bar).demand).to eq(10)
    end

    it 'sets the "baz" node demand to 10' do
      expect(graph.node(:baz).demand).to eq(10)
    end
  end

  describe 'UPDATE(V(no), demand, 10)' do
    before { result }

    it 'does not raise an error' do
      expect { result }.not_to raise_error
    end
  end

  describe 'UPDATE(V(no, nope, also_no), demand, 10)' do
    before { result }

    it 'does not raise an error' do
      expect { result }.not_to raise_error
    end
  end

  # UPDATE with EMISSIONS
  # ---------------------

  describe 'UPDATE(EMISSIONS(buildings_non_specified, energetic), other_ghg, 100.0)' do
    before { result }

    it 'sets the emissions to 100.0' do
      expect(gql.query_future('EMISSIONS(buildings_non_specified, energetic, other_ghg)')).to eq(100.0)
    end
  end

  describe 'UPDATE(EMISSIONS(households, energetic), co2, 500.0)' do
    before { result }

    it 'sets the co2 emissions to 500.0' do
      expect(gql.query_future('EMISSIONS(households, energetic, co2)')).to eq(500.0)
    end
  end

  describe 'UPDATE(EMISSIONS(invalid_sector, energetic), co2, 100.0)' do
    it 'raises an error when the emission key does not exist in the dataset' do
      # The full key 'invalid_sector_energetic_co2' must exist in the dataset
      expect { result }.to raise_error(Gql::CommandError, /not found in dataset/)
    end
  end

  describe 'UPDATE(EMISSIONS(energy, non_energetic), co2, 0.0)' do
    before { result }

    it 'accepts zero values' do
      expect { result }.not_to raise_error
    end

    it 'sets the emissions to 0.0' do
      expect(gql.query_future('EMISSIONS(energy, non_energetic, co2)')).to eq(0.0)
    end
  end

  describe 'UPDATE(EMISSIONS(energy_electricity_and_heat_production, energetic), other_ghg, 99.0)' do
    before { result }

    it 'handles multi-word subsectors with underscores' do
      # CSV: "Energy","Electricity and heat production","energetic","other_ghg"
      # Key: energy_electricity_and_heat_production_energetic_other_ghg
      expect(gql.query_future('EMISSIONS(energy_electricity_and_heat_production, energetic, other_ghg)')).to eq(99.0)
    end
  end

  describe 'UPDATE(EMISSIONS(industry, non_energetic), co2, 250.0)' do
    before { result }

    it 'works with non_energetic use type' do
      expect(gql.query_future('EMISSIONS(industry, non_energetic, co2)')).to eq(250.0)
    end
  end

  describe 'UPDATE(EMISSIONS(agriculture, energetic), other_ghg, 9999999.0)' do
    before { result }

    it 'accepts large values' do
      expect(gql.query_future('EMISSIONS(agriculture, energetic, other_ghg)')).to eq(9999999.0)
    end
  end

  describe 'UPDATE(EMISSIONS(waste, energetic), co2, 123.45)' do
    before { result }

    it 'works with different sectors' do
      expect(gql.query_future('EMISSIONS(waste, energetic, co2)')).to eq(123.45)
    end
  end

  describe 'UPDATE with both GHG types' do
    it 'allows updating co2' do
      gql.query_future('UPDATE(EMISSIONS(households, energetic), co2, 100.0)')
      expect(gql.query_future('EMISSIONS(households, energetic, co2)')).to eq(100.0)
    end

    it 'allows updating other_ghg' do
      gql.query_future('UPDATE(EMISSIONS(households, energetic), other_ghg, 200.0)')
      expect(gql.query_future('EMISSIONS(households, energetic, other_ghg)')).to eq(200.0)
    end

    it 'updates are independent' do
      gql.query_future('UPDATE(EMISSIONS(buildings, energetic), co2, 50.0)')
      gql.query_future('UPDATE(EMISSIONS(buildings, energetic), other_ghg, 75.0)')

      expect(gql.query_future('EMISSIONS(buildings, energetic, co2)')).to eq(50.0)
      expect(gql.query_future('EMISSIONS(buildings, energetic, other_ghg)')).to eq(75.0)
    end
  end

end
