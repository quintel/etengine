require 'spec_helper'

module Qernel
  describe Emissions do
    let(:area) { double('Area', analysis_year: 2023) }

    let(:dataset) do
      Qernel::Dataset.new(1).tap do |ds|
        ds.data[:emissions] = { emissions_data: data }
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
    end

    describe 'scope validation' do
      context 'with valid scope' do
        it 'allows creating a ScopedSector instance' do
          expect { emissions.scope(:households_non_specified_energetic) }.not_to raise_error
        end
      end

      context 'with invalid scope (does not exist in dataset)' do
        it 'allows creating the ScopedSector instance' do
          # Note: Validation happens on setter, not on scope() call
          expect { emissions.scope(:invalid_sector_energetic) }.not_to raise_error
        end

        it 'raises NoMethodError when trying to set a value' do
          invalid_scope = emissions.scope(:invalid_sector_energetic)
          expect { invalid_scope.co2 = 100.0 }.to raise_error(
            NoMethodError,
            /undefined method `co2=' for <Qernel::Emissions::ScopedSector invalid_sector_energetic>/
          )
        end

        it 'returns nil when trying to get a value (no validation on getter)' do
          invalid_scope = emissions.scope(:invalid_sector_energetic)
          expect(invalid_scope.co2).to be_nil
        end
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

      describe 'scope existence validation' do
        context 'with scope that does not exist in dataset' do
          before do
            # Create a scope that has no matching keys in dataset
            @invalid_scoped = emissions.scope(:nonexistent_sector_energetic)
          end

          it 'raises NoMethodError when setting any GHG value' do
            expect { @invalid_scoped.co2 = 100.0 }.to raise_error(NoMethodError)
            expect { @invalid_scoped.other_ghg = 50.0 }.to raise_error(NoMethodError)
          end

          it 'returns nil when getting any GHG value (no validation)' do
            expect(@invalid_scoped.co2).to be_nil
            expect(@invalid_scoped.other_ghg).to be_nil
          end

          it 'does not respond to setter methods' do
            expect(@invalid_scoped.respond_to?(:co2=)).to be false
            expect(@invalid_scoped.respond_to?(:other_ghg=)).to be false
          end

          it 'does not respond to getter methods' do
            expect(@invalid_scoped.respond_to?(:co2)).to be false
            expect(@invalid_scoped.respond_to?(:other_ghg)).to be false
          end
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
  end
end
