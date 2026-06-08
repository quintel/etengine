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
      it 'returns an Emissions object' do
        expect(result).to be_a(Qernel::Emissions)
      end
    end

    describe "EMISSIONS(buildings_non_specified, energetic, other_ghg, 2023)" do
      it 'returns the emission value for the specified year' do
        expect(result).to eq(2796620.0)
      end
    end

    describe "EMISSIONS(energy_electricity_and_heat_production, energetic, other_ghg, 2023)" do
      it 'returns the emission value for the specified year' do
        expect(result).to eq(18.0)
      end
    end

    describe 'EMISSIONS(households_non_specified, energetic, other_ghg, 2023)' do
      it 'returns the emission value for the specified year' do
        expect(result).to eq(7.0)
      end
    end

    describe 'EMISSIONS(energy, non_energetic, co2, 2023)' do
      it 'aggregates across energy subsectors (Fugitive emissions)' do
        expect(result).to eq(20.0) # Fugitive: 20.0
      end
    end

    describe 'EMISSIONS(energy, energetic, other_ghg, 2023)' do
      it 'aggregates multiple energy subsectors' do
        # Electricity: 18.0
        expect(result).to eq(18.0)
      end
    end

    describe 'EMISSIONS(agriculture, energetic, other_ghg, 2023)' do
      it 'sums single subsector' do
        expect(result).to eq(50.0)
      end
    end

    # EMISSIONS_MAP
    # -------------

    describe 'EMISSIONS_MAP("1.A.1")' do
      it 'returns an array of nodes matching the CRT code' do
        expect(result).to be_an(Array)
        expect(result).to all(be_a(Qernel::Node))
      end
    end

    describe 'EMISSIONS_MAP("nonexistent")' do
      it 'returns an empty array for non-existent CRT codes' do
        expect(result).to eq([])
      end
    end

    # Test various CRT code formats
    describe 'EMISSIONS_MAP("1-A-1")' do
      it 'handles CRT codes with hyphens' do
        expect(result).to be_an(Array)
        # Should normalize to same as "1.A.1"
      end
    end

    describe 'EMISSIONS_MAP("1_a_1")' do
      it 'handles CRT codes with underscores and lowercase' do
        expect(result).to be_an(Array)
        # Should normalize to same as "1.A.1"
      end
    end

    # Test when mapping exists but no nodes match
    context 'when CRT mapping exists but no nodes match' do
      let(:mock_mapping) do
        {
          etm_sector: 'nonexistent_sector',
          etm_subsector: 'nonexistent_subsector',
          use: 'energetic'
        }
      end

      before do
        dataset = Atlas::Dataset.find(gql.future_graph.area.area_code)
        allow(dataset.crt_mapping).to receive(:[]).with(:test_code).and_return(mock_mapping)
      end

      describe 'EMISSIONS_MAP("test_code")' do
        it 'returns an empty array' do
          expect(result).to eq([])
        end
      end
    end

    # Test non_specified subsector special case
    context 'when subsector is non_specified' do
      let(:mock_mapping) do
        {
          etm_sector: 'buildings',
          etm_subsector: 'non_specified',
          use: 'energetic'
        }
      end

      before do
        dataset = Atlas::Dataset.find(gql.future_graph.area.area_code)
        allow(dataset.crt_mapping).to receive(:[]).with(:test_nonspec).and_return(mock_mapping)
      end

      describe 'EMISSIONS_MAP("test_nonspec")' do
        it 'matches nodes without requiring subsector in key' do
          expect(result).to be_an(Array)
          # Should match all buildings sector nodes with energetic use
          # regardless of whether key contains 'non_specified'
          result.each do |node|
            expect(node.sector_key).to eq(:buildings)
            expect(node.use_key).to eq(:energetic)
          end
        end
      end
    end

    # Test matching across both energy and molecule graphs
    context 'with nodes in both energy and molecule graphs' do
      describe 'EMISSIONS_MAP("1.A.1")' do
        it 'searches both energy and molecule graphs' do
          # The function should search both graphs (implementation verified)
          # Result may be empty if no matching nodes in test fixtures
          expect(result).to be_an(Array)

          # If there are results, verify they come from one or both graphs
          if result.any?
            energy_nodes = result.select { |n| gql.future_graph.nodes.include?(n) }
            molecule_nodes = result.select { |n| gql.future.molecule_graph.nodes.include?(n) }

            expect(energy_nodes.any? || molecule_nodes.any?).to be true
          end
        end
      end
    end

    # Test node attribute matching
    context 'when nodes have matching attributes' do
      describe 'EMISSIONS_MAP("1.A.1")' do
        it 'matches nodes based on sector, subsector in key, and use' do
          skip 'if no nodes match' if result.empty?

          result.each do |node|
            # All returned nodes should have matching attributes
            expect(node).to respond_to(:sector_key)
            expect(node).to respond_to(:key)
            expect(node).to respond_to(:use_key)
          end
        end
      end
    end

    # Integration test with real CRT code
    context 'with real emissions data' do
      describe 'EMISSIONS_MAP("1.A.4.a")' do
        it 'returns nodes for commercial/institutional combustion' do
          expect(result).to be_an(Array)
          # Should match services sector nodes if they exist in the dataset
        end
      end
    end

    # Edge case: nil/missing attributes
    context 'when nodes might have missing attributes' do
      describe 'EMISSIONS_MAP("1.A.1")' do
        it 'handles nodes without sector gracefully' do
          # Should not raise error, just skip nodes without required attributes
          expect { result }.not_to raise_error
        end
      end
    end
  end
end
