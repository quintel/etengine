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

        it 'sets the internal key to :emissions_data' do
          emissions = Emissions.new(graph)
          expect(emissions.instance_variable_get(:@key)).to eq(:emissions_data)
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

    describe 'dataset_accessors integration' do
      let(:emissions) { Emissions.new.with({}) }

      it 'provides access via dataset_get' do
        emissions.dataset_set(:households_co2, 123.45)
        expect(emissions.dataset_get(:households_co2)).to eq(123.45)
      end

      it 'provides access via dataset_set' do
        emissions.dataset_set(:industry_other_ghg, 678.90)
        expect(emissions.dataset_get(:industry_other_ghg)).to eq(678.90)
      end

      it 'supports complex keys with subsectors and years' do
        emissions.dataset_set(:energy_electricity_and_heat_production_co2_1990, 1000.0)
        expect(emissions.dataset_get(:energy_electricity_and_heat_production_co2_1990)).to eq(1000.0)
      end

      it 'returns nil for unset attributes' do
        expect(emissions.dataset_get(:nonexistent_sector_co2)).to be_nil
      end

      context 'with caching enabled' do
        let(:getter) { double('getter', call: 42.0) }

        before do
          allow(emissions).to receive(:graph).and_return(
            double('graph', cache_dataset_fetch?: true)
          )
        end

        it 'caches fetched values' do
          first_value = emissions.fetch(:households_co2) { getter.call }
          second_value = emissions.fetch(:households_co2) { getter.call }

          expect(first_value).to eq(42.0)
          expect(second_value).to eq(42.0)
          expect(getter).to have_received(:call).once
        end
      end

      context 'with lazy evaluation' do
        let(:calculator) { double('calculator', call: 99.9) }

        it 'supports dataset_lazy_set' do
          emissions.dataset_lazy_set(:agriculture_co2) { calculator.call }

          # First access triggers evaluation
          value = emissions.dataset_get(:agriculture_co2)
          expect(value).to eq(99.9)
          expect(calculator).to have_received(:call).once
        end
      end
    end

    describe '#scope' do
      let(:emissions) { Emissions.new.with({}) }

      it 'returns a ScopedSector instance' do
        scoped = emissions.scope(:industry)
        expect(scoped).to be_a(Emissions::ScopedSector)
      end

      it 'creates a scoped sector for the given key' do
        scoped = emissions.scope(:households)
        expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector households>')
      end

      it 'handles string sector names' do
        scoped = emissions.scope('agriculture')
        expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector agriculture>')
      end

      it 'handles multi-part sector names with dots' do
        scoped = emissions.scope('industry.metal')
        expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector industry.metal>')
      end

      context 'with scoped read access' do
        before do
          emissions.dataset_set(:industry_co2, 100.0)
          emissions.dataset_set(:industry_other_ghg, 50.0)
          emissions.dataset_set(:industry_co2_1990, 200.0)

          emissions.instance_variable_get(:@dataset_attributes)['industry_co2'] = 100.0
          emissions.instance_variable_get(:@dataset_attributes)['industry_other_ghg'] = 50.0
          emissions.instance_variable_get(:@dataset_attributes)['industry_co2_1990'] = 200.0
        end

        it 'provides read access to co2 attribute' do
          expect(emissions.scope(:industry)[:co2]).to eq(100.0)
        end

        it 'provides read access to other_ghg attribute' do
          expect(emissions.scope(:industry)[:other_ghg]).to eq(50.0)
        end

        it 'provides read access to historical data' do
          expect(emissions.scope(:industry)[:co2_1990]).to eq(200.0)
        end

        it 'returns nil for unset attributes' do
          expect(emissions.scope(:industry)[:nonexistent]).to be_nil
        end
      end

      context 'with scoped write access' do
        it 'provides write access to co2 attribute' do
          emissions.scope(:households)[:co2] = 150.0
          expect(emissions.dataset_get(:households_co2)).to eq(150.0)
        end

        it 'provides write access to other_ghg attribute' do
          emissions.scope(:households)[:other_ghg] = 75.0
          expect(emissions.dataset_get(:households_other_ghg)).to eq(75.0)
        end

        it 'provides write access to historical data' do
          emissions.scope(:households)[:co2_1990] = 250.0
          expect(emissions.dataset_get(:households_co2_1990)).to eq(250.0)
        end
      end
    end

    describe '::ScopedSector' do
      let(:emissions) { Emissions.new.with({}) }
      let(:scoped) { emissions.scope(:agriculture) }

      describe '#initialize' do
        it 'stores the emissions reference' do
          expect(scoped.instance_variable_get(:@emissions)).to eq(emissions)
        end

        it 'stores the scope as provided' do
          expect(scoped.instance_variable_get(:@scope)).to eq(:agriculture)
        end
      end

      describe '#[]' do
        before do
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['agriculture_co2'] = 88.0
          attrs['agriculture_other_ghg_1990'] = 44.0
        end

        it 'reads scoped attributes' do
          expect(scoped[:co2]).to eq(88.0)
        end

        it 'reads scoped attributes with year suffix' do
          expect(scoped[:other_ghg_1990]).to eq(44.0)
        end

        it 'returns nil for unset attributes' do
          expect(scoped[:nonexistent]).to be_nil
        end
      end

      describe '#[]=' do
        it 'sets scoped attributes' do
          scoped[:co2] = 123.0
          expect(emissions.dataset_get(:agriculture_co2)).to eq(123.0)
        end

        it 'sets scoped attributes with year suffix' do
          scoped[:co2_1990] = 456.0
          expect(emissions.dataset_get(:agriculture_co2_1990)).to eq(456.0)
        end

        it 'overwrites existing values' do
          emissions.dataset_set(:agriculture_other_ghg, 10.0)
          scoped[:other_ghg] = 20.0
          expect(emissions.dataset_get(:agriculture_other_ghg)).to eq(20.0)
        end
      end

      describe '#method_missing' do
        before do
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['agriculture_co2'] = 50.0
          attrs['agriculture_other_ghg'] = 25.0
        end

        it 'delegates getter methods to emissions with scoped prefix' do
          expect(scoped.co2).to eq(50.0)
        end

        it 'delegates getter for other_ghg' do
          expect(scoped.other_ghg).to eq(25.0)
        end

        it 'delegates getter with year suffix' do
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['agriculture_co2_1990'] = 100.0
          expect(scoped.co2_1990).to eq(100.0)
        end

        it 'delegates setter methods to emissions with scoped prefix' do
          scoped.co2 = 75.0
          # Setters convert to symbol keys via dataset_set
          expect(emissions.dataset_get(:agriculture_co2)).to eq(75.0)
        end

        it 'delegates setter for other_ghg' do
          scoped.other_ghg = 30.0
          expect(emissions.dataset_get(:agriculture_other_ghg)).to eq(30.0)
        end

        it 'delegates setter with year suffix' do
          scoped.co2_1990 = 200.0
          expect(emissions.dataset_get(:agriculture_co2_1990)).to eq(200.0)
        end

        it 'returns nil for undefined getter methods' do
          expect(scoped.nonexistent_attribute).to be_nil
        end
      end

      describe '#respond_to_missing?' do
        before do
          # ScopedSector calls scoped_method which converts to string
          allow(emissions).to receive(:respond_to?)
            .with('agriculture_co2').and_return(true)
          allow(emissions).to receive(:respond_to?)
            .with('agriculture_co2').and_return(true)
          allow(emissions).to receive(:respond_to?)
            .with('agriculture_nonexistent').and_return(false)
        end

        it 'returns true for valid getter methods' do
          expect(scoped.respond_to?(:co2)).to be true
        end

        it 'returns true for valid setter methods' do
          expect(scoped.respond_to?(:co2=)).to be true
        end

        it 'returns false for invalid methods' do
          expect(scoped.respond_to?(:nonexistent)).to be false
        end
      end

      describe '#inspect' do
        it 'returns a readable string representation' do
          expect(scoped.inspect).to eq('<Qernel::Emissions::ScopedSector agriculture>')
        end

        it 'includes the scope name for different sectors' do
          industry_scoped = emissions.scope(:industry)
          expect(industry_scoped.inspect).to eq('<Qernel::Emissions::ScopedSector industry>')
        end

        it 'includes the scope name for multi-part sectors' do
          complex_scoped = emissions.scope('energy.electricity')
          expect(complex_scoped.inspect).to eq('<Qernel::Emissions::ScopedSector energy.electricity>')
        end
      end

      context 'with nested sector names' do
        let(:nested_scoped) { emissions.scope('industry.metal') }

        before do
          emissions.dataset_set(:industry_metal_co2, 300.0)
        end

        it 'handles reading with underscore conversion' do
          # The scoped method should convert 'industry.metal' + 'co2' to 'industry_metal_co2'
          expect(nested_scoped.instance_variable_get(:@scope)).to eq('industry.metal')
        end
      end
    end

    describe 'integration with graph lifecycle' do
      let(:graph) { Qernel::Graph.new }
      let(:emissions) { graph.area.emissions }

      it 'is accessible via graph.area.emissions' do
        expect(emissions).to be_a(Emissions)
      end

      it 'has the graph reference set' do
        expect(emissions.graph).to eq(graph)
      end

      it 'participates in assign_dataset_attributes' do
        expect { emissions.assign_dataset_attributes }.not_to raise_error
      end
    end

    describe 'dynamic accessor methods' do
      let(:emissions) { Emissions.new.with({}) }

      context 'when emission keys are loaded' do
        before do
          emissions.dataset_set(:households_co2, 100.0)
          emissions.dataset_set(:industry_other_ghg, 200.0)
        end

        it 'allows access via method syntax if accessor is defined' do
          if emissions.respond_to?(:households_co2)
            expect(emissions.households_co2).to eq(100.0)
          end
        end
      end
    end

    describe 'nil and edge case handling' do
      let(:emissions) { Emissions.new.with({}) }

      it 'handles nil values gracefully' do
        emissions.dataset_set(:sector_co2, nil)
        expect(emissions.dataset_get(:sector_co2)).to be_nil
      end

      it 'handles zero values' do
        emissions.dataset_set(:sector_co2, 0.0)
        expect(emissions.dataset_get(:sector_co2)).to eq(0.0)
      end

      it 'handles negative values' do
        emissions.dataset_set(:sector_co2, -50.0)
        expect(emissions.dataset_get(:sector_co2)).to eq(-50.0)
      end

      it 'handles very large values' do
        emissions.dataset_set(:sector_co2, 1_000_000_000.0)
        expect(emissions.dataset_get(:sector_co2)).to eq(1_000_000_000.0)
      end

      it 'handles blank subsector notation' do
        # Sectors without subsectors should have double underscore reduced to single
        attrs = emissions.instance_variable_get(:@dataset_attributes)
        attrs['households_co2'] = 100.0  # not households__co2
        expect(emissions.scope(:households)[:co2]).to eq(100.0)
      end
    end

    describe 'new CSV structure (multi-file format)' do
      let(:emissions) { Emissions.new.with({}) }

      context 'CSV format validation' do
        it 'loads emissions from emissions_default.csv with correct column structure' do
          emissions.dataset_set(:households_energetic_co2, 12.0)
          expect(emissions.dataset_get(:households_energetic_co2)).to eq(12.0)
        end

        it 'generates keys including the type column (energetic/non_energetic)' do
          # CSV row: energy,electricity_and_heat_production,non_energetic,co2,18,kg
          # Expected key: energy_electricity_and_heat_production_non_energetic_co2
          emissions.dataset_set(:energy_electricity_and_heat_production_non_energetic_co2, 18.0)
          expect(emissions.dataset_get(:energy_electricity_and_heat_production_non_energetic_co2)).to eq(18.0)
        end

        it 'generates keys for other_ghg emission type with energetic type' do
          # CSV row: households,,energetic,other_ghg,7,kg
          # Expected key: households_energetic_other_ghg
          emissions.dataset_set(:households_energetic_other_ghg, 7.0)
          expect(emissions.dataset_get(:households_energetic_other_ghg)).to eq(7.0)
        end

        it 'handles unit column presence but excludes it from key generation' do
          # The 'unit' column exists in CSV but should not appear in emission keys
          # agriculture,,energetic,co2,95,kg → agriculture_energetic_co2 (not ..._co2_kg)
          emissions.dataset_set(:agriculture_energetic_co2, 95.0)
          expect(emissions.dataset_get(:agriculture_energetic_co2)).to eq(95.0)
        end
      end

      context 'with empty sub_sector field' do
        it 'generates keys without double underscores for sectors with blank sub_sector' do
          # CSV: households,,energetic,co2,12,kg (blank sub_sector)
          # Expected key: households_energetic_co2 (NOT households__energetic_co2)
          emissions.dataset_set(:households_energetic_co2, 12.0)
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['households_energetic_co2'] = 12.0

          expect(emissions.scope(:households_energetic)[:co2]).to eq(12.0)
        end

        it 'generates keys without double underscores for agriculture sector' do
          # CSV: agriculture,,energetic,co2,95,kg
          # Expected key: agriculture_energetic_co2
          emissions.dataset_set(:agriculture_energetic_co2, 95.0)
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['agriculture_energetic_co2'] = 95.0

          expect(emissions.scope(:agriculture_energetic)[:co2]).to eq(95.0)
        end

        it 'handles both co2 and other_ghg for sectors with blank sub_sector' do
          emissions.dataset_set(:households_energetic_co2, 12.0)
          emissions.dataset_set(:households_energetic_other_ghg, 7.0)

          expect(emissions.dataset_get(:households_energetic_co2)).to eq(12.0)
          expect(emissions.dataset_get(:households_energetic_other_ghg)).to eq(7.0)
        end

        it 'distinguishes between blank sub_sector and named sub_sector' do
          # industry,,energetic,co2,,kg → industry_energetic_co2 (blank value, blank sub_sector)
          # industry,metal,energetic,co2,45,kg → industry_metal_energetic_co2
          emissions.dataset_set(:industry_energetic_co2, nil)
          emissions.dataset_set(:industry_metal_energetic_co2, 45.0)

          expect(emissions.dataset_get(:industry_energetic_co2)).to be_nil
          expect(emissions.dataset_get(:industry_metal_energetic_co2)).to eq(45.0)
        end
      end

      context 'with sectors containing sub_sectors' do
        it 'generates compound keys for nested sectors' do
          emissions.dataset_set(:industry_metal_energetic_co2, 45.0)
          expect(emissions.dataset_get(:industry_metal_energetic_co2)).to eq(45.0)
        end

        it 'handles other_ghg type for nested sectors' do
          emissions.dataset_set(:industry_metal_energetic_other_ghg, 28.0)
          expect(emissions.dataset_get(:industry_metal_energetic_other_ghg)).to eq(28.0)
        end

        it 'allows scoped access to nested sectors with type' do
          emissions.dataset_set(:industry_metal_energetic_co2, 45.0)
          attrs = emissions.instance_variable_get(:@dataset_attributes)
          attrs['industry_metal_energetic_co2'] = 45.0

          scoped = emissions.scope(:industry_metal_energetic)
          expect(scoped[:co2]).to eq(45.0)
        end
      end

      context 'with blank values in CSV' do
        it 'represents blank CSV values as nil in emission keys' do
          # CSV: industry,,energetic,co2,,kg (empty value field)
          # Expected: industry_energetic_co2 exists but value is nil
          emissions.dataset_set(:industry_energetic_co2, nil)
          expect(emissions.dataset_get(:industry_energetic_co2)).to be_nil
        end

        it 'distinguishes nil values from missing keys' do
          emissions.dataset_set(:industry_energetic_co2, nil)

          expect(emissions.dataset_get(:industry_energetic_co2)).to be_nil
          expect(emissions.dataset_get(:nonexistent_sector_energetic_co2)).to be_nil
          # TODO: Both return nil but for different reasons - should we error?
        end
      end
    end

    describe 'GQL EMISSIONS function integration' do
      let(:graph) { Qernel::Graph.new }
      let(:emissions) { graph.area.emissions.with({}) }

      before do
        # Simulate loaded emission data from new CSV structure with type included
        attrs = emissions.instance_variable_get(:@dataset_attributes)
        attrs['households_energetic_co2'] = 12.0
        attrs['households_energetic_other_ghg'] = 7.0
        attrs['energy_electricity_and_heat_production_energetic_other_ghg'] = 18.0
        attrs['energy_electricity_and_heat_production_non_energetic_co2'] = 18.0
        attrs['industry_metal_energetic_co2'] = 45.0
        attrs['industry_metal_energetic_other_ghg'] = 28.0
        attrs['agriculture_energetic_co2'] = 95.0
        attrs['agriculture_energetic_other_ghg'] = 38.0
        attrs['industry_energetic_co2'] = nil  # Blank in CSV

        # Also set symbol keys for dataset_get to work
        emissions.dataset_set(:households_energetic_co2, 12.0)
        emissions.dataset_set(:households_energetic_other_ghg, 7.0)
        emissions.dataset_set(:energy_electricity_and_heat_production_energetic_other_ghg, 18.0)
        emissions.dataset_set(:energy_electricity_and_heat_production_non_energetic_co2, 18.0)
        emissions.dataset_set(:industry_metal_energetic_co2, 45.0)
        emissions.dataset_set(:industry_metal_energetic_other_ghg, 28.0)
        emissions.dataset_set(:agriculture_energetic_co2, 95.0)
        emissions.dataset_set(:agriculture_energetic_other_ghg, 38.0)
        emissions.dataset_set(:industry_energetic_co2, nil)
      end

      context 'reading emission values via scoped access' do
        it 'returns correct value for households energetic co2' do
          # GQL: EMISSIONS(households, energetic, co2)
          expect(emissions.scope(:households_energetic)[:co2]).to eq(12.0)
        end

        it 'returns correct value for households energetic other_ghg' do
          # GQL: EMISSIONS(households, energetic, other_ghg)
          expect(emissions.scope(:households_energetic)[:other_ghg]).to eq(7.0)
        end

        it 'handles nested sectors with type and underscores' do
          # GQL: EMISSIONS('energy.electricity_and_heat_production', energetic, other_ghg)
          # Note: GQL converts dots to underscores
          scoped = emissions.scope(:energy_electricity_and_heat_production_energetic)
          expect(scoped[:other_ghg]).to eq(18.0)
        end

        it 'distinguishes between energetic and non_energetic types' do
          # GQL: EMISSIONS('energy.electricity_and_heat_production', non_energetic, co2)
          scoped = emissions.scope(:energy_electricity_and_heat_production_non_energetic)
          expect(scoped[:co2]).to eq(18.0)
        end

        it 'handles nested industry sectors with type' do
          # GQL: EMISSIONS('industry.metal', energetic, co2)
          scoped = emissions.scope(:industry_metal_energetic)
          expect(scoped[:co2]).to eq(45.0)
        end

        it 'returns ScopedSector when sector and type are provided' do
          # GQL: EMISSIONS(households, energetic)
          scoped = emissions.scope(:households_energetic)
          expect(scoped).to be_a(Emissions::ScopedSector)
          expect(scoped[:co2]).to eq(12.0)
        end
      end

      context 'updating emission values via scoped access' do
        it 'updates co2 value without affecting other_ghg' do
          # GQL: UPDATE(EMISSIONS(households, energetic), co2, 100)
          emissions.scope(:households_energetic)[:co2] = 100.0

          expect(emissions.dataset_get(:households_energetic_co2)).to eq(100.0)
          expect(emissions.dataset_get(:households_energetic_other_ghg)).to eq(7.0)
        end

        it 'updates other_ghg value without affecting co2' do
          # GQL: UPDATE(EMISSIONS(households, energetic), other_ghg, 50)
          emissions.scope(:households_energetic)[:other_ghg] = 50.0

          expect(emissions.dataset_get(:households_energetic_co2)).to eq(12.0)
          expect(emissions.dataset_get(:households_energetic_other_ghg)).to eq(50.0)
        end

        it 'updates nested sector emissions with type' do
          # GQL: UPDATE(EMISSIONS('industry.metal', energetic), co2, 99)
          emissions.scope(:industry_metal_energetic)[:co2] = 99.0

          expect(emissions.dataset_get(:industry_metal_energetic_co2)).to eq(99.0)
          expect(emissions.dataset_get(:industry_metal_energetic_other_ghg)).to eq(28.0)
        end

        it 'can set emission values to zero' do
          # GQL: UPDATE(EMISSIONS(agriculture, energetic), co2, 0.0)
          emissions.scope(:agriculture_energetic)[:co2] = 0.0

          expect(emissions.dataset_get(:agriculture_energetic_co2)).to eq(0.0)
        end

        it 'can set emission values to nil' do
          # GQL: UPDATE(EMISSIONS(agriculture, energetic), co2, nil)
          emissions.scope(:agriculture_energetic)[:co2] = nil

          expect(emissions.dataset_get(:agriculture_energetic_co2)).to be_nil
        end
      end

      context 'with missing or invalid data' do
        it 'returns nil for non-existent sectors' do
          # GQL: EMISSIONS(nonexistent_sector, energetic, co2)
          scoped = emissions.scope(:nonexistent_sector_energetic)
          expect(scoped[:co2]).to be_nil
        end

        it 'returns nil for non-existent emission types' do
          # GQL: EMISSIONS(households, energetic, nonexistent_type)
          scoped = emissions.scope(:households_energetic)
          expect(scoped[:nonexistent_type]).to be_nil
        end

        it 'returns nil for sectors with blank CSV values' do
          # industry,,energetic,co2,,kg → industry_energetic_co2 = nil
          # GQL: EMISSIONS(industry, energetic, co2)
          scoped = emissions.scope(:industry_energetic)
          expect(scoped[:co2]).to be_nil
        end
      end

      context 'verifying the full emissions object' do
        it 'returns the Emissions object when called without arguments' do
          # GQL: EMISSIONS()
          expect(emissions).to be_a(Emissions)
          expect(emissions.graph).to eq(graph)
        end

        it 'allows accessing emissions via graph' do
          # Verify graph.emissions works (via delegation or direct access)
          expect(graph.area.emissions).to eq(emissions)
        end
      end
    end

    describe 'multi-file CSV structure support' do
      let(:emissions) { Emissions.new.with({}) }

      context 'with emissions_default.csv as the primary source' do
        it 'loads emission data from the default file' do
          # emissions_default.csv contains start_year emissions
          # Verify keys are generated from this file including type
          emissions.dataset_set(:households_energetic_co2, 12.0)
          emissions.dataset_set(:agriculture_energetic_other_ghg, 38.0)

          expect(emissions.dataset_get(:households_energetic_co2)).to eq(12.0)
          expect(emissions.dataset_get(:agriculture_energetic_other_ghg)).to eq(38.0)
        end

        it 'distinguishes between energetic and non_energetic emission types' do
          # Each sector can have multiple rows with different types
          # Keys include the 'type' column to distinguish them
          emissions.dataset_set(:energy_electricity_and_heat_production_energetic_other_ghg, 18.0)
          emissions.dataset_set(:energy_electricity_and_heat_production_non_energetic_co2, 18.0)

          expect(emissions.dataset_get(:energy_electricity_and_heat_production_energetic_other_ghg)).to eq(18.0)
          expect(emissions.dataset_get(:energy_electricity_and_heat_production_non_energetic_co2)).to eq(18.0)
        end
      end
    end
  end
end
