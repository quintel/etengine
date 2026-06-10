require 'spec_helper'

module Qernel
  describe Emissions do
    # Builds an index in the shape produced by
    # Etsource::Dataset::Import#build_emissions_index from
    # [sector, subsector, use] rows.
    def self.emissions_index(rows)
      index = { sectors: {}, subsectors: {}, scopes: {}, ghgs: { co2: true, other_ghg: true } }

      rows.each do |sector, subsector, use|
        key = :"#{sector}_#{subsector}"
        sectors = (index[:sectors][sector.to_sym] ||= [])
        sectors << key unless sectors.include?(key)

        index[:subsectors][key] = true
        index[:scopes][:"#{key}_#{use}"] = true
      end

      index
    end

    INDEX = emissions_index([
      %w[energy electricity_and_heat_production energetic],
      %w[energy fugitive_emissions non_energetic],
      %w[households non_specified energetic],
      %w[buildings non_specified energetic],
      %w[industry steel non_energetic],
      %w[industry chemicals non_energetic],
      %w[industry non_specified energetic],
      %w[agriculture non_specified energetic],
      %w[agriculture non_specified non_energetic]
    ]).freeze

    let(:area) { double('Area', analysis_year: 2023) }

    let(:dataset) do
      Qernel::Dataset.new(1).tap do |ds|
        ds.data[:emissions] = { emissions_data: data, emissions_index: INDEX }
      end
    end

    let(:graph) { double('Graph', area: area, dataset: dataset) }
    let(:emissions) { Emissions.new(graph).tap(&:assign_dataset_attributes) }
    let(:data) { {} }

    describe '#initialize' do
      context 'with a graph' do
        let(:graph) { Qernel::Graph.new }

        it 'assigns the graph' do
          emissions = Emissions.new(graph)
          expect(emissions.graph).to eq(graph)
        end

        it 'sets the dataset_key to :emissions_data' do
          emissions = Emissions.new(graph)
          expect(emissions.dataset_key).to eq(:emissions_data)
        end
      end

      context 'without a graph' do
        it 'does not assign the graph' do
          emissions = Emissions.new
          expect(emissions.graph).to be_nil
        end

        it 'still sets the dataset_key' do
          emissions = Emissions.new
          expect(emissions.dataset_key).to eq(:emissions_data)
        end
      end
    end

    describe '#scope' do
      it 'returns a ScopedSector instance' do
        scoped = emissions.scope(:households_non_specified_energetic)
        expect(scoped).to be_a(Emissions::ScopedSector)
      end

      it 'sets the correct scope' do
        scoped = emissions.scope(:agriculture_non_specified_energetic)
        expect(scoped.instance_variable_get(:@scope)).to eq(:agriculture_non_specified_energetic)
      end

      it 'raises ArgumentError for a scope not present in the dataset' do
        expect { emissions.scope(:invalid_sector_energetic) }
          .to raise_error(ArgumentError, /unknown emissions scope/)
      end
    end

    describe '#valid_scope?' do
      it 'returns true for a sector_subsector_use combination from the data' do
        expect(emissions.valid_scope?(:energy_fugitive_emissions_non_energetic)).to be true
      end

      it 'returns false for unknown combinations' do
        expect(emissions.valid_scope?(:energy_fugitive_emissions_energetic)).to be false
        expect(emissions.valid_scope?(:invalid_sector_energetic)).to be false
      end
    end

    describe '#ghgs' do
      it 'returns the GHG types from the index' do
        expect(emissions.ghgs.keys).to contain_exactly(:co2, :other_ghg)
      end
    end

    describe Emissions::ScopedSector do
      let(:scoped) { emissions.scope(:households_non_specified_energetic) }

      before do
        emissions[:households_non_specified_energetic_other_ghg_2023] = 50.0
        emissions[:agriculture_non_specified_energetic_other_ghg_2023] = 25.0
      end

      describe 'GHG accessors' do
        it 'reads values with the scoped prefix' do
          expect(scoped.other_ghg).to eq(50.0)
        end

        it 'reads values for a different scope' do
          other_scoped = emissions.scope(:agriculture_non_specified_energetic)
          expect(other_scoped.other_ghg).to eq(25.0)
        end

        it 'writes values with the scoped prefix' do
          scoped.other_ghg = 75.0
          expect(emissions.dataset_get(:households_non_specified_energetic_other_ghg_2023)).to eq(75.0)
        end

        it 'writes values for a different scope' do
          other_scoped = emissions.scope(:agriculture_non_specified_energetic)
          other_scoped.other_ghg = 30.0
          expect(emissions.dataset_get(:agriculture_non_specified_energetic_other_ghg_2023)).to eq(30.0)
        end

        it 'returns nil when the scope has no value for the GHG' do
          expect(scoped.co2).to be_nil
        end

        it 'allows setting a GHG which has no value yet (runtime UPDATE values)' do
          scoped.co2 = 300.0
          expect(emissions.dataset_get(:households_non_specified_energetic_co2_2023)).to eq(300.0)
        end

        it 'raises NoMethodError for attributes which are not GHGs' do
          expect { scoped.nonexistent_attribute }.to raise_error(NoMethodError)
          expect { scoped.arbitrary_key = 100.0 }.to raise_error(NoMethodError)
        end

        it 'responds to the GHG getters and setters' do
          expect(scoped).to respond_to(:co2, :co2=, :other_ghg, :other_ghg=)
        end

        it 'does not respond to attributes which are not GHGs' do
          expect(scoped).not_to respond_to(:arbitrary_key)
        end
      end

      describe 'year targeting' do
        it 'reads and writes the requested year' do
          scoped_1990 = emissions.scope(:households_non_specified_energetic, 1990)
          scoped_1990.other_ghg = 12.0

          expect(emissions.dataset_get(:households_non_specified_energetic_other_ghg_1990)).to eq(12.0)
          expect(scoped_1990.other_ghg).to eq(12.0)
          expect(scoped.other_ghg).to eq(50.0)
        end
      end

      describe '[]' do
        before do
          emissions[:agriculture_non_specified_energetic_other_ghg_2023] = 123.45
        end

        let(:scoped) { emissions.scope(:agriculture_non_specified_energetic) }

        it 'returns the value for existing keys' do
          expect(scoped[:other_ghg]).to eq(123.45)
        end

        it 'returns nil for non-existing keys' do
          expect(scoped[:co2]).to be_nil
        end
      end

      describe '[]=' do
        let(:scoped) { emissions.scope(:industry_non_specified_energetic) }

        it 'sets the value' do
          scoped[:other_ghg] = 999.0
          expect(emissions.dataset_get(:industry_non_specified_energetic_other_ghg_2023)).to eq(999.0)
        end
      end

      describe '#inspect' do
        it 'returns a readable string representation' do
          expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector households_non_specified_energetic>')
        end
      end

      describe 'edge cases based on actual CSV data' do
        let(:scoped) { emissions.scope(:energy_fugitive_emissions_non_energetic) }

        before do
          emissions[:energy_fugitive_emissions_non_energetic_co2_2023] = 0.0
          emissions[:energy_electricity_and_heat_production_energetic_other_ghg_2023] = 0.0
          emissions[:buildings_non_specified_energetic_other_ghg_2023] = 0.0
          emissions[:agriculture_non_specified_energetic_other_ghg_2023] = 0.0
          emissions[:agriculture_non_specified_non_energetic_co2_2023] = 0.0
        end

        it 'handles zero values' do
          scoped.co2 = 0.0
          expect(emissions.dataset_get(:energy_fugitive_emissions_non_energetic_co2_2023)).to eq(0.0)
        end

        it 'handles large values' do
          buildings_scoped = emissions.scope(:buildings_non_specified_energetic)
          buildings_scoped.other_ghg = 9999999.0
          expect(emissions.dataset_get(:buildings_non_specified_energetic_other_ghg_2023)).to eq(9999999.0)
        end

        it 'handles multi-word subsector scopes' do
          # CSV: "Energy","Electricity and heat production","energetic","other_ghg"
          # Scope: energy_electricity_and_heat_production_energetic
          multi_scoped = emissions.scope(:energy_electricity_and_heat_production_energetic)
          multi_scoped.other_ghg = 275.0
          expect(emissions.dataset_get(:energy_electricity_and_heat_production_energetic_other_ghg_2023)).to eq(275.0)
        end

        it 'works with multi-part keys from real dataset' do
          scoped.co2 = 100.0
          expect(emissions.dataset_get(:energy_fugitive_emissions_non_energetic_co2_2023)).to eq(100.0)

          ag_energetic = emissions.scope(:agriculture_non_specified_energetic)
          ag_energetic.other_ghg = 200.0
          expect(emissions.dataset_get(:agriculture_non_specified_energetic_other_ghg_2023)).to eq(200.0)

          ag_non_energetic = emissions.scope(:agriculture_non_specified_non_energetic)
          ag_non_energetic.co2 = 300.0
          expect(emissions.dataset_get(:agriculture_non_specified_non_energetic_co2_2023)).to eq(300.0)
        end
      end
    end

    describe '#sum' do
      let(:data) do
        {
          energy_electricity_and_heat_production_energetic_other_ghg_2023: 18.0,
          energy_electricity_and_heat_production_energetic_other_ghg_1990: 25.0,
          energy_fugitive_emissions_non_energetic_co2_2023: 20.0,
          energy_fugitive_emissions_non_energetic_co2_1990: 30.0,
          agriculture_non_specified_energetic_other_ghg_2023: 50.0,
          agriculture_non_specified_energetic_other_ghg_1990: 75.0,
          agriculture_non_specified_non_energetic_co2_2023: 75.0,
          agriculture_non_specified_non_energetic_co2_1990: 100.0,
          industry_steel_non_energetic_co2_2023: 100.0,
          industry_chemicals_non_energetic_co2_2023: 50.0,
          buildings_non_specified_energetic_other_ghg_2023: 2796620.0,
          buildings_non_specified_energetic_other_ghg_1990: 3000000.0
        }
      end

      it 'sums emissions across multiple subsectors for a sector' do
        # Energy has two subsectors with different use types, so this matches
        # non_energetic (fugitive) only.
        result = emissions.sum(:energy, :non_energetic, :co2, 2023)
        expect(result).to eq(20.0)
      end

      it 'aggregates energy sector with energetic other_ghg for default year' do
        result = emissions.sum(:energy, :energetic, :other_ghg)
        expect(result).to eq(18.0)
      end

      it 'sums emissions for 1990 year when specified' do
        result = emissions.sum(:energy, :non_energetic, :co2, 1990)
        expect(result).to eq(30.0)
      end

      it 'handles single subsector aggregation' do
        result = emissions.sum(:agriculture, :energetic, :other_ghg, 2023)
        expect(result).to eq(50.0)
      end

      it 'sums multiple subsectors in industry' do
        # Industry has steel (100.0) + chemicals (50.0) = 150.0
        result = emissions.sum(:industry, :non_energetic, :co2, 2023)
        expect(result).to eq(150.0)
      end

      it 'accepts a full subsector key instead of a sector' do
        result = emissions.sum(:buildings_non_specified, :energetic, :other_ghg, 2023)
        expect(result).to eq(2796620.0)
      end

      it 'returns 0 when no matches are found' do
        result = emissions.sum(:nonexistent_sector, :energetic, :co2, 2023)
        expect(result).to eq(0)
      end

      it 'normalizes sector names with dashes and mixed case' do
        result = emissions.sum(:'Buildings-Non-Specified', :energetic, :other_ghg, 2023)
        expect(result).to eq(2796620.0)
      end

      it 'includes runtime UPDATE modifications in sum' do
        emissions[:energy_fugitive_emissions_non_energetic_co2_2023] = 50.0

        result = emissions.sum(:energy, :non_energetic, :co2, 2023)
        expect(result).to eq(50.0)
      end

      it 'uses analysis_year when year parameter is not provided' do
        allow(area).to receive(:analysis_year).and_return(1990)

        result = emissions.sum(:energy, :energetic, :other_ghg)
        expect(result).to eq(25.0)
      end

      it 'handles nil values gracefully' do
        emissions[:buildings_non_specified_energetic_other_ghg_2023] = nil

        result = emissions.sum(:buildings, :energetic, :other_ghg, 2023)
        expect(result).to eq(0)
      end

      it 'sums multiple values correctly' do
        energetic = emissions.sum(:agriculture, :energetic, :other_ghg, 2023)
        non_energetic = emissions.sum(:agriculture, :non_energetic, :co2, 2023)

        expect(energetic).to eq(50.0)
        expect(non_energetic).to eq(75.0)
      end

      it 'does not match "energetic" substring in "non_energetic" (regression test)' do
        emissions[:agriculture_non_specified_energetic_other_ghg_2023] = 1263.93948
        emissions[:agriculture_non_specified_non_energetic_other_ghg_2023] = 18361.45468

        result = emissions.sum(:agriculture, :energetic, :other_ghg, 2023)
        expect(result).to eq(1263.93948)

        result_non = emissions.sum(:agriculture, :non_energetic, :other_ghg, 2023)
        expect(result_non).to eq(18361.45468)
      end
    end
  end
end
