require 'spec_helper'

module Gql::Runtime::Functions
  describe Lookup, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }

    let(:result) do |example|
      gql.query_future(example.metadata[:example_group][:description])
    end

    describe 'CURVE_SET_VARIANTS(weather)' do
      it 'returns ["default", "empty"]' do
        expect(result).to eq(%w[default empty])
      end
    end

    # WEATHER_PROPERTY
    # ----------------

    describe 'WEATHER_PROPERTY(flh_of_energy_power_wind_turbine_coastal)' do
      it 'returns a value' do
        expect(result).to eq(2350)
      end
    end

    describe 'WEATHER_PROPERTY(invalid)' do
      it 'raises an error' do
        expect { result }.to raise_error(/No row called :invalid/)
      end
    end

    context 'when the weather curve set has no weather_properties.csv' do
      describe 'WEATHER_PROPERTY(flh_of_energy_power_wind_turbine_coastal)' do
        before do
          gql.future_graph.area.weather_curve_set = 'empty'
        end

        it 'raises an error' do
          expect { result }.to raise_error(/No weather_properties.csv found/)
        end
      end
    end

    # EMISSIONS
    # ---------

    describe 'EMISSIONS()' do
      it 'returns a Qernel::Emissions object' do
        expect(result).to be_a(Qernel::Emissions)
      end
    end

    describe 'EMISSIONS(households_non_specified)' do
      it 'returns a Qernel::Emissions::ScopedSector object' do
        expect(result).to be_a(Qernel::Emissions::ScopedSector)
      end
    end

    describe "EMISSIONS(buildings_non_specified, energetic, other_ghg)" do
      it 'returns the emission value' do
        expect(result).to eq(2796620.0)
      end
    end

    describe "EMISSIONS(energy_electricity_and_heat_production, energetic, other_ghg)" do
      it 'returns the emission value' do
        expect(result).to eq(18.0)
      end
    end

    describe 'EMISSIONS(households_non_specified, energetic, co2)' do
      it 'returns the emission value' do
        expect(result).to eq(12.0)
      end
    end
  end
end
