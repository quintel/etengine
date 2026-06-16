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

  describe 'UPDATE(EMISSIONS(households_non_specified, energetic), other_ghg, 500.0)' do
    before { result }

    it 'sets the other_ghg emissions to 500.0' do
      expect(gql.query_future('EMISSIONS(households_non_specified, energetic, other_ghg)')).to eq(500.0)
    end
  end

  describe 'UPDATE(EMISSIONS(energy_fugitive_emissions, non_energetic), co2, 0.0)' do
    before { result }

    it 'accepts zero values' do
      expect { result }.not_to raise_error
    end

    it 'sets the emissions to 0.0' do
      expect(gql.query_future('EMISSIONS(energy_fugitive_emissions, non_energetic, co2)')).to eq(0.0)
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

  describe 'UPDATE(EMISSIONS(industry_non_specified, energetic), other_ghg, 250.0)' do
    before { result }

    it 'works with industry sector' do
      expect(gql.query_future('EMISSIONS(industry_non_specified, energetic, other_ghg)')).to eq(250.0)
    end
  end

  describe 'UPDATE(EMISSIONS(agriculture_non_specified, energetic), other_ghg, 9999999.0)' do
    before { result }

    it 'accepts large values' do
      expect(gql.query_future('EMISSIONS(agriculture_non_specified, energetic, other_ghg)')).to eq(9999999.0)
    end
  end

  describe 'UPDATE(EMISSIONS(waste_non_specified, non_energetic), co2, 123.45)' do
    before { result }

    it 'works with different sectors' do
      expect(gql.query_future('EMISSIONS(waste_non_specified, non_energetic, co2)')).to eq(123.45)
    end
  end

  describe 'UPDATE with different emission keys' do
    it 'allows updating one key' do
      gql.query_future('UPDATE(EMISSIONS(households_non_specified, energetic), other_ghg, 100.0)')
      expect(gql.query_future('EMISSIONS(households_non_specified, energetic, other_ghg)')).to eq(100.0)
    end

    it 'allows updating another key' do
      gql.query_future('UPDATE(EMISSIONS(agriculture_non_specified, non_energetic), co2, 200.0)')
      expect(gql.query_future('EMISSIONS(agriculture_non_specified, non_energetic, co2)')).to eq(200.0)
    end

    it 'updates are independent' do
      gql.query_future('UPDATE(EMISSIONS(buildings_non_specified, energetic), other_ghg, 50.0)')
      gql.query_future('UPDATE(EMISSIONS(energy_fugitive_emissions, non_energetic), co2, 75.0)')

      expect(gql.query_future('EMISSIONS(buildings_non_specified, energetic, other_ghg)')).to eq(50.0)
      expect(gql.query_future('EMISSIONS(energy_fugitive_emissions, non_energetic, co2)')).to eq(75.0)
    end
  end

end
