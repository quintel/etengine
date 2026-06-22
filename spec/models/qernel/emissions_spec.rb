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
      let(:emissions) { Emissions.new.with({}) }
      let(:scoped) { emissions.scope(:households_non_specified_energetic) }

      before do
        emissions[:households_non_specified_energetic_other_ghg] = 50.0
        emissions[:agriculture_non_specified_energetic_other_ghg] = 25.0
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
          expect(emissions.dataset_get(:households_non_specified_energetic_other_ghg)).to eq(75.0)
        end

        it 'delegates setter for a different scope' do
          other_scoped = emissions.scope(:agriculture_non_specified_energetic)
          other_scoped.other_ghg = 30.0
          expect(emissions.dataset_get(:agriculture_non_specified_energetic_other_ghg)).to eq(30.0)
        end

        it 'raises NoMethodError for undefined getter methods' do
          expect { scoped.nonexistent_attribute }.to raise_error(NoMethodError)
          expect { scoped.invalid_emission }.to raise_error(NoMethodError)
        end

        it 'raises NoMethodError for setter keys that do not exist in the dataset' do
          expect { scoped.arbitrary_key = 100.0 }.to raise_error(NoMethodError)
          expect { scoped.custom_emission_type = 200.0 }.to raise_error(NoMethodError)
          expect { scoped.nonexistent = 300.0 }.to raise_error(NoMethodError)
        end

        it 'allows setters for emission keys that exist in the dataset' do
          expect { scoped.other_ghg = 2.0 }.not_to raise_error
          expect(emissions.dataset_get(:households_non_specified_energetic_other_ghg)).to eq(2.0)
        end
      end

      describe '#respond_to_missing?' do
        it 'returns true for valid GHG types that exist' do
          expect(scoped.respond_to?(:other_ghg)).to be true
        end

        it 'returns true for setter methods where the key exists in dataset' do
          expect(scoped.respond_to?(:other_ghg=)).to be true
        end

        it 'returns false for setter methods where the key does not exist in dataset' do
          expect(scoped.respond_to?(:invalid_key=)).to be false
          expect(scoped.respond_to?(:co2=)).to be false  # co2 doesn't exist for this scope
          expect(scoped.respond_to?(:arbitrary_name=)).to be false
        end

        it 'returns false for getter methods where the key does not exist in dataset' do
          expect(scoped.respond_to?(:invalid_key)).to be false
          expect(scoped.respond_to?(:co2)).to be false  # co2 doesn't exist for this scope
          expect(scoped.respond_to?(:nonexistent_attribute)).to be false
        end
      end

      describe '[]' do
        before do
          emissions[:agriculture_non_specified_energetic_other_ghg] = 123.45
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
          expect(emissions.dataset_get(:industry_non_specified_energetic_other_ghg)).to eq(999.0)
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
          emissions[:energy_fugitive_emissions_non_energetic_co2] = 0.0
          emissions[:energy_electricity_and_heat_production_energetic_other_ghg] = 0.0
          emissions[:buildings_non_specified_energetic_other_ghg] = 0.0
        end

        it 'handles zero values' do
          scoped.co2 = 0.0
          expect(emissions.dataset_get(:energy_fugitive_emissions_non_energetic_co2)).to eq(0.0)
        end

        it 'handles large values' do
          buildings_scoped = emissions.scope(:buildings_non_specified_energetic)
          buildings_scoped.other_ghg = 9999999.0
          expect(emissions.dataset_get(:buildings_non_specified_energetic_other_ghg)).to eq(9999999.0)
        end

        it 'handles multi-word subsector scopes' do
          # CSV: "Energy","Electricity and heat production","energetic","other_ghg"
          # Scope: energy_electricity_and_heat_production_energetic
          multi_scoped = emissions.scope(:energy_electricity_and_heat_production_energetic)
          multi_scoped.other_ghg = 275.0
          expect(emissions.dataset_get(:energy_electricity_and_heat_production_energetic_other_ghg)).to eq(275.0)
        end

        it 'works with multi-part keys from real dataset' do
          scoped.co2 = 100.0
          expect(emissions.dataset_get(:energy_fugitive_emissions_non_energetic_co2)).to eq(100.0)

          # Test agriculture keys that actually exist in default dataset
          ag_energetic = emissions.scope(:agriculture_non_specified_energetic)
          ag_energetic.other_ghg = 200.0
          expect(emissions.dataset_get(:agriculture_non_specified_energetic_other_ghg)).to eq(200.0)

          ag_non_energetic = emissions.scope(:agriculture_non_specified_non_energetic)
          ag_non_energetic.co2 = 300.0
          expect(emissions.dataset_get(:agriculture_non_specified_non_energetic_co2)).to eq(300.0)
        end
      end
    end
  end
end
