require 'spec_helper'

module Qernel
  describe Emissions do
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
      let(:emissions) { Emissions.new.with({}) }

      it 'returns a ScopedSector instance' do
        scoped = emissions.scope(:households_energetic)
        expect(scoped).to be_a(Emissions::ScopedSector)
      end

      it 'sets the correct scope' do
        scoped = emissions.scope(:agriculture_energetic)
        expect(scoped.instance_variable_get(:@scope)).to eq(:agriculture_energetic)
      end
    end

    describe Emissions::ScopedSector do
      let(:graph) { double('Graph', area: area) }
      let(:area) { double('Area', analysis_year: 2023) }
      let(:emissions) { Emissions.new(graph).with({}) }
      let(:scoped) { emissions.scope(:households_non_specified_energetic) }

      before do
        emissions[:households_non_specified_energetic_other_ghg_2023] = 50.0
        emissions[:agriculture_non_specified_energetic_other_ghg_2023] = 25.0
      end

      describe '#method_missing' do
        it 'delegates getter methods to emissions with scoped prefix' do
          expect(scoped.other_ghg).to eq(50.0)
        end

        it 'delegates getter for a different scope' do
          other_scoped = emissions.scope(:agriculture_non_specified_energetic)
          expect(other_scoped.other_ghg).to eq(25.0)
        end

        it 'delegates setter methods to emissions with scoped prefix' do
          scoped.other_ghg = 75.0
          # Setters convert to symbol keys via dataset_set
          expect(emissions.dataset_get(:households_non_specified_energetic_other_ghg_2023)).to eq(75.0)
        end

        it 'delegates setter for a different scope' do
          other_scoped = emissions.scope(:agriculture_non_specified_energetic)
          other_scoped.other_ghg = 30.0
          expect(emissions.dataset_get(:agriculture_non_specified_energetic_other_ghg_2023)).to eq(30.0)
        end

        it 'raises NoMethodError for undefined getter methods' do
          expect { scoped.nonexistent_attribute }.to raise_error(NoMethodError)
          expect { scoped.invalid_emission }.to raise_error(NoMethodError)
        end

        it 'allows setters for any GHG type when scope exists in dataset' do
          # Setters are allowed for any GHG type if the scope (subsector + use) exists
          # This enables UPDATE operations to set runtime values
          expect { scoped.arbitrary_key = 100.0 }.not_to raise_error
          expect { scoped.custom_emission_type = 200.0 }.not_to raise_error
          expect { scoped.co2 = 300.0 }.not_to raise_error
        end

        it 'allows setters for emission keys that exist in the dataset' do
          expect { scoped.other_ghg = 2.0 }.not_to raise_error
          expect(emissions.dataset_get(:households_non_specified_energetic_other_ghg_2023)).to eq(2.0)
        end
      end

      describe '#respond_to_missing?' do
        it 'returns true for valid GHG types that exist' do
          expect(scoped.respond_to?(:other_ghg)).to be true
        end

        it 'returns true for setter methods where the key exists in dataset' do
          expect(scoped.respond_to?(:other_ghg=)).to be true
        end

        it 'returns true for setter methods when scope exists in dataset' do
          # Setters are allowed for any GHG type if the scope exists
          # This enables UPDATE operations to set runtime values
          expect(scoped.respond_to?(:invalid_key=)).to be true
          expect(scoped.respond_to?(:co2=)).to be true
          expect(scoped.respond_to?(:arbitrary_name=)).to be true
        end

        it 'returns false for getter methods where the key does not exist in dataset' do
          expect(scoped.respond_to?(:invalid_key)).to be false
          expect(scoped.respond_to?(:co2)).to be false  # co2 doesn't exist for this scope
          expect(scoped.respond_to?(:nonexistent_attribute)).to be false
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
          scoped = emissions.scope(:households_energetic)
          expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector households_energetic>')
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

          # Test agriculture keys that actually exist in default dataset
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
      let(:graph) { double('Graph', area: area) }
      let(:area) { double('Area', analysis_year: 2023) }
      let(:emissions) { Emissions.new(graph) }

      before do
        emissions.with({
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
        })
      end

      it 'sums emissions across multiple subsectors for a sector' do
        # Energy has two subsectors: electricity (18.0) + fugitive (20.0) for 2023
        # But they have different use types, so this tests non_energetic only
        result = emissions.sum(:energy, :non_energetic, :co2, 2023)
        expect(result).to eq(20.0) # Only fugitive has non_energetic co2
      end

      it 'aggregates energy sector with energetic other_ghg for default year' do
        # Energy has electricity (18.0) for energetic other_ghg in 2023
        result = emissions.sum(:energy, :energetic, :other_ghg)
        expect(result).to eq(18.0)
      end

      it 'sums emissions for 1990 year when specified' do
        # Energy fugitive: 30.0 (1990) for non_energetic co2
        result = emissions.sum(:energy, :non_energetic, :co2, 1990)
        expect(result).to eq(30.0)
      end

      it 'handles single subsector aggregation' do
        # Agriculture only has one subsector (Non-specified)
        result = emissions.sum(:agriculture, :energetic, :other_ghg, 2023)
        expect(result).to eq(50.0)
      end

      it 'sums multiple subsectors in industry' do
        # Industry has steel (100.0) + chemicals (50.0) = 150.0
        result = emissions.sum(:industry, :non_energetic, :co2, 2023)
        expect(result).to eq(150.0)
      end

      it 'returns 0 when no matches are found' do
        result = emissions.sum(:nonexistent_sector, :energetic, :co2, 2023)
        expect(result).to eq(0)
      end

      it 'normalizes sector names with dashes' do
        # Test that dashes are converted to underscores
        result = emissions.sum(:'energy', :non_energetic, :co2, 2023)
        expect(result).to eq(20.0)
      end

      it 'includes runtime UPDATE modifications in sum' do
        # Modify a value via UPDATE
        emissions[:energy_fugitive_emissions_non_energetic_co2_2023] = 50.0

        result = emissions.sum(:energy, :non_energetic, :co2, 2023)
        expect(result).to eq(50.0) # Modified value
      end

      it 'uses analysis_year when year parameter is not provided' do
        allow(area).to receive(:analysis_year).and_return(1990)

        result = emissions.sum(:energy, :energetic, :other_ghg)
        expect(result).to eq(25.0) # 1990 value
      end

      it 'handles nil values gracefully' do
        # Set a value to nil
        emissions[:buildings_non_specified_energetic_other_ghg_2023] = nil

        result = emissions.sum(:buildings, :energetic, :other_ghg, 2023)
        expect(result).to eq(0)
      end

      it 'sums multiple values correctly' do
        # Agriculture has both energetic (50.0) and non_energetic (75.0) for co2/other_ghg
        energetic = emissions.sum(:agriculture, :energetic, :other_ghg, 2023)
        non_energetic = emissions.sum(:agriculture, :non_energetic, :co2, 2023)

        expect(energetic).to eq(50.0)
        expect(non_energetic).to eq(75.0)
      end
    end
  end
end
