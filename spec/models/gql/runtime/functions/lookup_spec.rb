require 'spec_helper'

module Gql::Runtime::Functions
  describe Lookup, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }
    let(:molecule_graph) { gql.future.molecules }

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

    describe "EMISSIONS(buildings_non_specified, energetic, other_ghg)" do
      it 'returns the present-year emission value' do
        expect(result).to eq(2796620.0)
      end
    end

    describe "EMISSIONS(energy_electricity_and_heat_production, energetic, other_ghg)" do
      it 'returns the present-year emission value' do
        expect(result).to eq(18.0)
      end
    end

    describe 'EMISSIONS(households_non_specified, energetic, other_ghg)' do
      it 'returns the present-year emission value' do
        expect(result).to eq(7.0)
      end
    end

    describe 'EMISSIONS(households_non_specified, energetic, other_ghg, 1990)' do
      it 'returns the 1990 baseline emission value' do
        expect(result).to eq(10.0)
      end
    end

    # MUSE
    # ----

    describe 'MUSE(energetic)' do
      it 'returns [Node(m_right_one)]' do
        expect(result).to eq([molecule_graph.node(:m_right_one)])
      end
    end

    describe 'MUSE(non_energetic)' do
      it 'returns [Node(m_right_two), Node(m_waste)]' do
        expect(result).to eq([
          molecule_graph.node(:m_right_two),
          molecule_graph.node(:m_waste)
        ])
      end
    end

    describe 'MUSE(energetic, non_energetic)' do
      it 'returns [Node(m_right_one), Node(m_right_two), Node(m_waste)]' do
        expect(result).to eq([
          molecule_graph.node(:m_right_one),
          molecule_graph.node(:m_right_two),
          molecule_graph.node(:m_waste)
        ])
      end
    end

    describe 'MUSE(undefined)' do
      it 'returns []' do
        expect(result).to eq([])
      end
    end

    # SECTOR - scheme-based mapping lookups (energy graph)
    # ---------------------------------------------------

    def keys_of(nodes)
      nodes.map(&:key).sort
    end

    describe 'legacy one-argument SECTOR' do
      it 'is unchanged: returns the namespace-sector nodes' do
        legacy = gql.query_future('SECTOR(nosector)')
        direct = gql.future_graph.sector_nodes(:nosector)

        expect(keys_of(legacy)).to eq(keys_of(direct))
      end
    end

    describe "SECTOR(klimaattafel, 'Industrie')" do
      it 'returns the labelled energy nodes in that klimaattafel' do
        expect(keys_of(result)).to eq(%i[bar baz foo])
      end
    end

    describe "SECTOR(ipcc_crt_code_agg, '1.A.1')" do
      it 'returns only the energetic-use node for that IPCC category' do
        expect(keys_of(result)).to eq(%i[bar])
      end
    end

    describe "SECTOR(ipcc_crt_code_agg, '1.B')" do
      it 'returns only the non-energetic-use node (pair correctness)' do
        expect(keys_of(result)).to eq(%i[baz])
      end
    end

    describe "SECTOR(ipcc_crt_code_agg, '1.A.1', '1.A.2')" do
      it 'returns the union over several values' do
        expect(keys_of(result)).to eq(%i[bar foo])
      end
    end

    describe 'SECTOR(sector_label, industry_refineries)' do
      it 'resolves the canonical key directly (both uses)' do
        expect(keys_of(result)).to eq(%i[bar baz])
      end
    end

    describe "SECTOR(klimaattafel, 'Gebouwde omgeving')" do
      it 'resolves a quoted value containing a space' do
        expect(keys_of(result)).to eq(%i[buildings_space_heating_demand])
      end
    end

    describe "SECTOR(klimaattafel, 'Landbouw')" do
      it 'returns [] for a valid value with no labelled nodes' do
        expect(result).to eq([])
      end
    end

    describe "SECTOR(impossible, 'x')" do
      it 'raises naming the valid schemes' do
        expect { result }.to raise_error(/Valid schemes.*klimaattafel/m)
      end
    end

    describe "SECTOR(klimaattafel, 'Nonexistent')" do
      it 'raises for an unknown value' do
        expect { result }.to raise_error(/Unknown value "Nonexistent"/)
      end
    end

    # Blank / "-" cells. The `other_heating,energetic` row has a "-" ipcc cell
    # (fixture) and the `lft` node is labelled to it.

    describe "SECTOR(klimaattafel, 'Mobiliteit')" do
      it 'reaches a "-"-celled row through a populated scheme' do
        expect(keys_of(result)).to eq(%i[lft])
      end
    end

    describe 'SECTOR(sector_label, other_heating)' do
      it 'reaches the "-"-celled row by its canonical key' do
        expect(keys_of(result)).to eq(%i[lft])
      end
    end

    describe "SECTOR(ipcc_crt_code_agg, '-')" do
      it 'raises: a "-" cell is unqueryable, not a category' do
        expect { result }.to raise_error(/Unknown value/)
      end
    end

    describe "EMISSIONS(ipcc_crt_code_agg, '-', co2)" do
      it 'raises: the mapped form rejects a blank value too' do
        expect { result }.to raise_error(/Unknown value/)
      end
    end

    # MSECTOR - scheme-based mapping lookups (molecule graph)
    # ------------------------------------------------------

    describe "MSECTOR(ipcc_crt_code_agg, '5')" do
      it 'returns the labelled molecule node' do
        expect(keys_of(result)).to eq(%i[m_waste])
      end
    end

    describe "MSECTOR(klimaattafel, 'Elektriciteit')" do
      it 'returns only molecule nodes (disjoint from the energy graph)' do
        expect(keys_of(result)).to eq(%i[m_waste])
      end
    end

    describe "SECTOR(ipcc_crt_code_agg, '5')" do
      it 'returns [] on the energy graph for a molecule-only pair' do
        expect(result).to eq([])
      end
    end

    describe 'legacy one-argument MSECTOR' do
      it 'is unchanged: routes to the namespace-sector molecule filter' do
        expect(gql.query_future('MSECTOR(anything)'))
          .to eq(molecule_graph.sector_nodes(:anything))
      end
    end

    # EMISSIONS - mapped scheme form
    # ------------------------------

    describe "EMISSIONS(ipcc_crt_code_agg, '1.A.1', other_ghg)" do
      it 'sums the store over the resolved pairs (missing keys as zero)' do
        # energy_electricity_and_heat_production_energetic_other_ghg = 18.0
        # industry_refineries_energetic_other_ghg is absent -> 0.0
        expect(result).to eq(18.0)
      end
    end

    describe "EMISSIONS(ipcc_crt_code_agg, '1.A.1', other_ghg, 1990)" do
      it 'reads the 1990 baseline keys' do
        expect(result).to eq(25.0)
      end
    end

    describe "EMISSIONS(ipcc_crt_code_agg, '3', co2)" do
      it 'sums only the non-energetic rows the mapping lists' do
        # agriculture_non_specified_non_energetic_co2 = 75.0; the energetic
        # agriculture row (also Landbouw) is not under IPCC 3.
        expect(result).to eq(75.0)
      end
    end

    describe "EMISSIONS(klimaattafel, 'Landbouw', other_ghg)" do
      it 'unions energetic and non-energetic rows of the value' do
        # agriculture energetic (50.0) + agriculture non_energetic (100.0)
        expect(result).to eq(150.0)
      end
    end

    describe "EMISSIONS(ipcc_crt_code_agg, '1.A.1')" do
      it 'raises without a GHG argument' do
        expect { result }.to raise_error(Gql::GqlError, /needs a GHG argument/)
      end
    end

    it 'rejects UPDATE on a mapped EMISSIONS expression' do
      expect do
        gql.query_future("UPDATE(EMISSIONS(ipcc_crt_code_agg, '1.A.1', co2), co2, 1.0)")
      end.to raise_error(StandardError)
    end
  end
end
