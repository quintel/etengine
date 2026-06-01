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
      let(:scoped) { emissions.scope(:households_energetic) }

      describe '#method_missing' do
        before do
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['households_energetic_co2'] = 50.0
          attrs['households_energetic_other_ghg'] = 25.0
        end

        it 'delegates getter methods to emissions with scoped prefix' do
          expect(scoped.co2).to eq(50.0)
        end

        it 'delegates getter for other_ghg' do
          expect(scoped.other_ghg).to eq(25.0)
        end

        it 'delegates getter with year suffix' do
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['households_energetic_co2_1990'] = 100.0
          expect(scoped.co2_1990).to eq(100.0)
        end

        it 'delegates setter methods to emissions with scoped prefix' do
          scoped.co2 = 75.0
          # Setters convert to symbol keys via dataset_set
          expect(emissions.dataset_get(:households_energetic_co2)).to eq(75.0)
        end

        it 'delegates setter for other_ghg' do
          scoped.other_ghg = 30.0
          expect(emissions.dataset_get(:households_energetic_other_ghg)).to eq(30.0)
        end

        it 'delegates setter with year suffix' do
          scoped.co2_1990 = 200.0
          expect(emissions.dataset_get(:households_energetic_co2_1990)).to eq(200.0)
        end

        it 'returns nil for undefined getter methods' do
          expect(scoped.nonexistent_attribute).to be_nil
        end

        it 'raises NoMethodError for invalid setter keys' do
          expect { scoped.invalid_key = 100.0 }.to raise_error(NoMethodError)
        end

        it 'raises NoMethodError for setter with typo in GHG type' do
          expect { scoped.co2_typo = 100.0 }.to raise_error(NoMethodError)
        end

        it 'allows all valid GHG types' do
          expect { scoped.co2 = 1.0 }.not_to raise_error
          expect { scoped.other_ghg = 2.0 }.not_to raise_error
          expect { scoped.n2o = 3.0 }.not_to raise_error
          expect { scoped.ch4 = 4.0 }.not_to raise_error
          expect { scoped.hfc = 5.0 }.not_to raise_error
          expect { scoped.pfc = 6.0 }.not_to raise_error
          expect { scoped.sf6 = 7.0 }.not_to raise_error
          expect { scoped.nf3 = 8.0 }.not_to raise_error
        end

        it 'allows GHG types with year suffix' do
          expect { scoped.co2_1990 = 100.0 }.not_to raise_error
          expect { scoped.other_ghg_2020 = 200.0 }.not_to raise_error
        end
      end

      describe '#respond_to_missing?' do
        it 'returns true for valid GHG types' do
          expect(scoped.respond_to?(:co2)).to be true
          expect(scoped.respond_to?(:other_ghg)).to be true
          expect(scoped.respond_to?(:n2o)).to be true
        end

        it 'returns true for valid GHG types with year suffix' do
          expect(scoped.respond_to?(:co2_1990)).to be true
          expect(scoped.respond_to?(:other_ghg_2020)).to be true
        end

        it 'returns true for valid setter methods' do
          expect(scoped.respond_to?(:co2=)).to be true
          expect(scoped.respond_to?(:other_ghg=)).to be true
        end

        it 'returns false for invalid attribute names' do
          expect(scoped.respond_to?(:invalid_key)).to be false
          expect(scoped.respond_to?(:co2_typo)).to be false
        end
      end

      describe '#valid_emission_key?' do
        it 'returns true for valid GHG types' do
          expect(scoped.valid_emission_key?('co2')).to be true
          expect(scoped.valid_emission_key?('other_ghg')).to be true
          expect(scoped.valid_emission_key?('n2o')).to be true
          expect(scoped.valid_emission_key?('ch4')).to be true
        end

        it 'returns true for GHG types with year suffix' do
          expect(scoped.valid_emission_key?('co2_1990')).to be true
          expect(scoped.valid_emission_key?('other_ghg_2020')).to be true
        end

        it 'returns false for invalid keys' do
          expect(scoped.valid_emission_key?('invalid')).to be false
          expect(scoped.valid_emission_key?('co2_typo')).to be false
          expect(scoped.valid_emission_key?('random_string')).to be false
        end

        it 'returns false for empty strings' do
          expect(scoped.valid_emission_key?('')).to be false
        end
      end

      describe '[]' do
        before do
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['agriculture_energetic_co2'] = 123.45
        end

        let(:scoped) { emissions.scope(:agriculture_energetic) }

        it 'returns the value for existing keys' do
          expect(scoped[:co2]).to eq(123.45)
        end

        it 'returns nil for non-existing keys' do
          expect(scoped[:other_ghg]).to be_nil
        end
      end

      describe '[]=' do
        let(:scoped) { emissions.scope(:industry_energetic) }

        it 'sets the value' do
          scoped[:co2] = 999.0
          expect(emissions.dataset_get(:industry_energetic_co2)).to eq(999.0)
        end
      end

      describe '#inspect' do
        it 'returns a readable string representation' do
          scoped = emissions.scope(:households_energetic)
          expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector households_energetic>')
        end
      end

      describe 'edge cases based on actual CSV data' do
        let(:scoped) { emissions.scope(:energy_non_energetic) }

        it 'handles zero values' do
          scoped.co2 = 0.0
          expect(emissions.dataset_get(:energy_non_energetic_co2)).to eq(0.0)
        end

        it 'handles large values' do
          scoped.other_ghg = 9999999.0
          expect(emissions.dataset_get(:energy_non_energetic_other_ghg)).to eq(9999999.0)
        end

        it 'handles multi-word subsector scopes' do
          # CSV: "Energy","Electricity and heat production","energetic","other_ghg"
          # Scope: energy_electricity_and_heat_production_energetic
          multi_scoped = emissions.scope(:energy_electricity_and_heat_production_energetic)
          multi_scoped.other_ghg = 275.0
          expect(emissions.dataset_get(:energy_electricity_and_heat_production_energetic_other_ghg)).to eq(275.0)
        end

        it 'allows both co2 and other_ghg for same scope' do
          scoped.co2 = 100.0
          scoped.other_ghg = 200.0
          expect(emissions.dataset_get(:energy_non_energetic_co2)).to eq(100.0)
          expect(emissions.dataset_get(:energy_non_energetic_other_ghg)).to eq(200.0)
        end

        it 'rejects invalid GHG types' do
          expect { scoped.invalid_ghg = 100.0 }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
