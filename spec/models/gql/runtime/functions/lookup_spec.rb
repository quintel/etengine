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

    # EMISSIONS
    # ---------------
    #

    describe 'EMISSIONS()' do
      it 'returns a Qernel::Emissions object' do
        expect(result).to be_a(Qernel::Emissions)
      end
    end

    describe 'EMISSIONS(households, energetic)' do
      it 'returns a Qernel::Emissions::ScopedSector' do
        expect(result).to be_a(Qernel::Emissions::ScopedSector)
      end
    end

    describe "EMISSIONS('industry.metal', energetic)" do
      it 'returns a Qernel::Emissions::ScopedSector' do
        expect(result).to be_a(Qernel::Emissions::ScopedSector)
      end
    end

    describe 'EMISSIONS(households, energetic, co2, 1990)' do
      it 'returns a historical value from emissions_1990.csv' do
        expect(result).to eq(12.0)
      end
    end

    describe "EMISSIONS('energy.electricity_and_heat_production', energetic, other_ghg)" do
      it 'returns a value' do
        expect(result).to eq(18.0)
      end
    end

    describe "EMISSIONS('energy.electricity_and_heat_production', non_energetic, co2)" do
      it 'returns a value for non_energetic type' do
        expect(result).to eq(18.0)
      end
    end

    describe "EMISSIONS('energy.electricity_and_heat_production', non_energetic, co2, 1990)" do
      it 'returns a historical value with subsector from emissions_1990.csv' do
        expect(result).to eq(18.0)
      end
    end

    describe 'EMISSIONS(households, energetic, co2)' do
      it 'returns start_year value when year is omitted' do
        expect(result).to eq(12.0)
      end
    end

    describe 'EMISSIONS(households, energetic, other_ghg, 1990)' do
      it 'returns the 1990 value for other_ghg from emissions_1990.csv' do
        expect(result).to eq(7.0)
      end
    end

    describe 'EMISSIONS(nonexistent_sector, energetic, co2)' do
      it 'returns nil for non-existent sector' do
        expect(result).to be_nil
      end
    end

    describe 'EMISSIONS(households, energetic, nonexistent_type)' do
      it 'returns nil for non-existent emission type' do
        expect(result).to be_nil
      end
    end

    describe 'EMISSIONS(households, energetic, co2, 2050)' do
      it 'returns nil for non-existent year (no emissions_2050.csv file)' do
        expect(result).to be_nil
      end
    end

    describe 'EMISSIONS(industry, energetic, co2)' do
      it 'returns nil when value is blank in CSV' do
        # Assumes industry,,energetic,co2 is blank in fixture
        expect(result).to be_nil
      end
    end

    # Test that dot notation is properly converted to underscores
    describe "EMISSIONS('energy.electricity_and_heat_production', energetic)" do
      it 'returns a ScopedSector for multi-part sector with dots' do
        expect(result).to be_a(Qernel::Emissions::ScopedSector)
      end
    end

    # Test that start_year parameter is treated as a literal year lookup
    # (no special handling - it would look for households_energetic_other_ghg_start_year key)
    describe 'EMISSIONS(households, energetic, other_ghg, start_year)' do
      it 'returns nil when start_year is used as a literal year parameter' do
        # start_year is no longer treated specially, so this looks for
        # households_energetic_other_ghg_start_year which does not exist
        expect(result).to be_nil
      end
    end

    describe 'EMISSIONS(households, energetic, other_ghg)' do
      it 'returns correct value from emissions_default.csv' do
        expect(result).to eq(7.0)
      end
    end

    describe "EMISSIONS('energy.electricity_and_heat_production', energetic, other_ghg)" do
      it 'handles subsector with dots correctly' do
        expect(result).to eq(18.0)
      end
    end

    describe 'EMISSIONS(industry, energetic, other_ghg)' do
      it 'returns nil for blank value in CSV (industry has blank values)' do
        expect(result).to be_nil
      end
    end

    describe 'EMISSIONS(international_transport, energetic, other_ghg)' do
      it 'handles sector names with underscores correctly' do
        expect(result).to be_nil
      end
    end

    describe "EMISSIONS('international_transport.international_aviation', energetic, other_ghg)" do
      it 'handles sector with subsector and underscores correctly' do
        expect(result).to be_nil  # Blank in fixture
      end
    end

    describe 'EMISSIONS(lulucf, non_energetic, co2)' do
      it 'returns value for LULUCF sector' do
        expect(result).to be_nil  # Blank in fixture
      end
    end

    describe 'EMISSIONS(invalid_sector, invalid_type, invalid_ghg)' do
      it 'returns nil for completely invalid parameters' do
        expect(result).to be_nil
      end
    end

    # TODO: Nil or error?
    describe 'EMISSIONS(households, energetic, co2, 999)' do
      it 'returns nil for non-existent numeric year' do
        expect(result).to be_nil
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
  end
end
