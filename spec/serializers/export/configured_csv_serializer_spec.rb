# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Export::ConfiguredCSVSerializer do
  let(:config) do
    {
      schema: [
        { name: 'Group' },
        { name: 'Category', type: 'literal' },
        { name: 'Present', type: 'present' },
        { name: 'Future', type: 'future' }
      ],
      rows: [
        { 'Group' => 'G1', 'Category' => 'C1', 'Present' => 'query_1', 'Future' => 'query_1' },
        { 'Group' => 'G1', 'Category' => 'C2', 'Present' => 'query_2', 'Future' => 'query_3' }
      ]
    }
  end

  let(:query_1) { Gquery.new(query: 'IF(GRAPH().present?, -> { 1 }, -> { 10 })', unit: 'PJ') }
  let(:query_2) { Gquery.new(query: '2', unit: 'MJ') }
  let(:query_3) { Gquery.new(query: '3', unit: 'MWh') }

  let(:serializer) { described_class.new(config, Scenario.default.gql) }

  before do
    allow(Gquery).to receive(:get).with('query_1').and_return(query_1)
    allow(Gquery).to receive(:get).with('query_2').and_return(query_2)
    allow(Gquery).to receive(:get).with('query_3').and_return(query_3)
  end

  # ------------------------------------------------------------------------------------------------

  context 'when given a valid config' do
    it 'includes the CSV headers' do
      expect(serializer.data[0]).to eq(%w[Group Category Present Future])
    end

    it 'includes the first row' do
      expect(serializer.data[1]).to eq(%w[G1 C1 1 10])
    end

    it 'includes the second row' do
      expect(serializer.data[2]).to eq(%w[G1 C2 2 3])
    end
  end

  context 'when given a "query" column' do
    let(:config) do
      {
        schema: [{ name: 'Val', type: 'query' }],
        rows: [{ 'Val' => 'query_1' }]
      }
    end

    it 'includes the CSV headers' do
      expect(serializer.data[0]).to eq(['Present Val', 'Future Val', 'Val Unit'])
    end

    it 'includes the row of data' do
      expect(serializer.data[1]).to eq(%w[1 10 PJ])
    end
  end

  context 'when given a "query" column with custom labels' do
    let(:config) do
      {
        schema: [
          { name: 'Val', type: 'query', present_label: 'P', future_label: 'F', unit_label: 'U' }
        ],
        rows: [
          { 'Val' => 'query_1' }
        ]
      }
    end

    it 'includes the CSV headers' do
      expect(serializer.data[0]).to eq(%w[P F U])
    end

    it 'includes the row of data' do
      expect(serializer.data[1]).to eq(%w[1 10 PJ])
    end
  end

  context 'when a query does not exist' do
    before do
      allow(Gquery).to receive(:get).with('query_1').and_call_original
    end

    it 'fails' do
      expect { serializer.data[0] }.to raise_error(/missing gquery/i)
    end
  end

  context 'when a row is missing a column' do
    let(:config) do
      super().tap do |conf|
        conf[:rows][0].delete('Present')
      end
    end

    it 'includes the first row with an empty value' do
      expect(serializer.data[1]).to eq(['G1', 'C1', '', '10'])
    end
  end

  context 'when a row has a surplus column' do
    let(:config) do
      super().tap do |conf|
        conf[:rows][0]['New'] = 'Value'
      end
    end

    it 'includes the CSV headers' do
      expect(serializer.data[0]).to eq(%w[Group Category Present Future])
    end

    it 'includes the first row without the surplus column' do
      expect(serializer.data[1]).to eq(%w[G1 C1 1 10])
    end
  end

  context 'when given mapping-driven rows' do
    # Real pairs from spec/fixtures/etsource/config/sector_mapping.csv, joined against the real
    # labelled fixture nodes (spec/fixtures/etsource/graphs). In mapping-file order:
    #
    #   energy_electricity_and_heat_production/energetic -> Energy,   emissions_sector set, 0 nodes
    #   industry_refineries/energetic                    -> Industry, node `bar`   (dual-use label)
    #   industry_refineries/non_energetic                -> Industry, node `baz`   (dual-use label)
    #   industry_non_specified/energetic                 -> emissions_sector blank -> excluded
    #                                                        (node `foo` exists but must not appear)
    #   buildings_non_specified/energetic                -> Buildings, node `buildings_space_heating_demand`
    #   households_non_specified/energetic               -> 0 nodes
    #   agriculture_non_specified/energetic              -> 0 nodes
    #   agriculture_non_specified/non_energetic           -> 0 nodes
    #   waste_non_specified/non_energetic                -> Waste, node `m_waste` (molecule graph)
    #   energy_fugitive_emissions/non_energetic          -> 0 nodes
    #   other_heating/energetic                          -> Other, node `lft`, blank ipcc cell

    let(:config) do
      {
        schema: [
          { name: 'Sector', type: 'sector_mapping', value: 'emissions_sector' },
          { name: 'Key', type: 'node_attribute', value: 'key' },
          { name: 'IPCC', type: 'sector_mapping', value: 'ipcc_crt_code_agg' }
        ],
        rows: { require: 'emissions_sector' }
      }
    end

    let(:gql) { Scenario.default.gql }
    let(:serializer) { described_class.new(config, gql, period: :future) }

    let(:node_bar) do
      instance_double(
        'Qernel::Node',
        emissions?: true,
        node_api: instance_double(
          'Qernel::NodeApi::EnergyApi', key: :bar, direct_reporting_emissions_co2_production: nil
        )
      )
    end
    let(:node_baz) do
      instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :baz))
    end
    let(:node_foo) do
      instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :foo))
    end
    let(:node_buildings) do
      instance_double(
        'Qernel::Node', emissions?: true,
        node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :buildings_space_heating_demand)
      )
    end
    let(:node_lft) do
      instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :lft))
    end
    let(:node_waste) do
      instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::MoleculeApi', key: :m_waste))
    end

    let(:energy_nodes) do
      { bar: node_bar, baz: node_baz, foo: node_foo, buildings_space_heating_demand: node_buildings, lft: node_lft }
    end

    before do
      allow(gql.future.graph).to receive(:node) { |key| energy_nodes[key.to_sym] }
      allow(gql.future).to receive(:molecules)
        .and_return(instance_double('Qernel::Graph').tap { |g| allow(g).to receive(:node).with(:m_waste).and_return(node_waste) })
    end

    it 'includes the CSV headers' do
      expect(serializer.data[0]).to eq(%w[Sector Key IPCC])
    end

    it 'emits rows in mapping-file order, skipping pairs with zero labelled nodes' do
      expect(serializer.data[1..].map { |row| row[1] }).to eq(
        %w[bar baz buildings_space_heating_demand m_waste lft]
      )
    end

    it 'excludes a pair whose require column cell is blank, even though it has a labelled node' do
      expect(serializer.data.flatten).not_to include('foo')
    end

    context 'with an "order_by" rule' do
      let(:config) do
        {
          schema: [{ name: 'Key', type: 'node_attribute', value: 'key' }],
          rows: { require: 'emissions_sector', order_by: 'ipcc_crt_code' }
        }
      end

      it 'orders rows by the raw value of the order_by column, not the mapping-file order' do
        # ipcc_crt_code: bar 1.A.1.b, buildings 1.A.4.a, baz 1.B.2.a.iv, m_waste 5, lft blank.
        expect(serializer.data[1..].flatten).to eq(
          %w[bar buildings_space_heating_demand baz m_waste lft]
        )
      end

      it 'sorts a pair with a blank order_by cell last' do
        expect(serializer.data.last).to eq(['lft'])
      end
    end

    context 'when a labelled node is not in the :emissions group' do
      before { allow(node_baz).to receive(:emissions?).and_return(false) }

      it 'excludes it, even though its pair matches an exported row' do
        expect(serializer.data.flatten).not_to include('baz')
      end

      it 'still includes the other node under the same dual-use label' do
        expect(serializer.data.flatten).to include('bar')
      end
    end

    it 'renders the raw display value of the require column (not a slug)' do
      expect(serializer.data[1][0]).to eq('Industry')
      expect(serializer.data[4][0]).to eq('Waste')
    end

    it 'joins a dual-use label by the node\'s own (label, use) pair, not by name alone' do
      # `bar` and `baz` share sector_label industry_refineries but differ in `use`, and land under
      # different IPCC codes as a result.
      expect(serializer.data[1]).to eq(%w[Industry bar 1.A.1])
      expect(serializer.data[2]).to eq(%w[Industry baz 1.B])
    end

    it 'includes molecule-graph nodes alongside energy nodes' do
      expect(serializer.data[4]).to eq(%w[Waste m_waste 5])
    end

    it 'renders a raw value with punctuation unchanged' do
      expect(serializer.data[1][2]).to eq('1.A.1')
    end

    it 'renders a blank mapping cell as an empty string' do
      expect(serializer.data[5]).to eq(['Other', 'lft', ''])
    end

    context 'with an isolated pair (stubbed Etsource::Sectors)' do
      let(:sectors) { instance_double(Etsource::Sectors) }
      let(:pair) { %i[industry_refineries energetic] }
      let(:raw_row) { Atlas::SectorMapping::RawRow.new(pair, { emissions_sector: 'Industry' }) }

      before do
        allow(Etsource::Sectors).to receive(:new).and_return(sectors)
        allow(sectors).to receive(:mapping).and_return({ emissions_sector: {} })
        allow(sectors).to receive(:raw_rows).and_return([raw_row])
        allow(sectors).to receive(:node_index).with(:molecules).and_return({})
      end

      context 'sorting nodes within a pair' do
        let(:config) do
          {
            schema: [{ name: 'Key', type: 'node_attribute', value: 'key' }],
            rows: { require: 'emissions_sector' }
          }
        end

        let(:node_z) do
          instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :z_node))
        end
        let(:node_a) do
          instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :a_node))
        end

        before do
          allow(sectors).to receive(:node_index).with(:energy).and_return({ pair => %i[z_node a_node] })
          allow(gql.future.graph).to receive(:node).with(:z_node).and_return(node_z)
          allow(gql.future.graph).to receive(:node).with(:a_node).and_return(node_a)
        end

        it 'sorts the expanded nodes by key, regardless of node_index order' do
          expect(serializer.data[1..].map { |row| row[0] }).to eq(%w[a_node z_node])
        end
      end

      context 'with an "order_by" rule and rows tied on that column' do
        let(:pair_a) { %i[pair_a energetic] }
        let(:pair_b) { %i[pair_b energetic] }
        let(:pair_c) { %i[pair_c energetic] }

        let(:raw_row_a) { Atlas::SectorMapping::RawRow.new(pair_a, { emissions_sector: 'A', ipcc_crt_code: '1' }) }
        let(:raw_row_b) { Atlas::SectorMapping::RawRow.new(pair_b, { emissions_sector: 'B', ipcc_crt_code: '1' }) }
        let(:raw_row_c) { Atlas::SectorMapping::RawRow.new(pair_c, { emissions_sector: 'C', ipcc_crt_code: '0' }) }

        let(:config) do
          {
            schema: [{ name: 'Key', type: 'node_attribute', value: 'key' }],
            rows: { require: 'emissions_sector', order_by: 'ipcc_crt_code' }
          }
        end

        let(:node_a) do
          instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :node_a))
        end
        let(:node_b) do
          instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :node_b))
        end
        let(:node_c) do
          instance_double('Qernel::Node', emissions?: true, node_api: instance_double('Qernel::NodeApi::EnergyApi', key: :node_c))
        end

        before do
          allow(sectors).to receive(:mapping).and_return({ emissions_sector: {}, ipcc_crt_code: {} })
          # File order: A, B, C. A and B tie on ipcc_crt_code ("1"); C has a lower code ("0").
          allow(sectors).to receive(:raw_rows).and_return([raw_row_a, raw_row_b, raw_row_c])
          allow(sectors).to receive(:node_index).with(:energy).and_return(
            pair_a => [:node_a], pair_b => [:node_b], pair_c => [:node_c]
          )
          allow(gql.future.graph).to receive(:node).with(:node_a).and_return(node_a)
          allow(gql.future.graph).to receive(:node).with(:node_b).and_return(node_b)
          allow(gql.future.graph).to receive(:node).with(:node_c).and_return(node_c)
        end

        it 'sorts by the order_by value first, breaking ties by mapping-file order' do
          expect(serializer.data[1..].flatten).to eq(%w[node_c node_a node_b])
        end
      end

      context 'when a node_attribute value is nil (node not in the :emissions group)' do
        let(:config) do
          {
            schema: [
              { name: 'Key', type: 'node_attribute', value: 'key' },
              { name: 'CO2', type: 'node_attribute', value: 'direct_reporting_emissions_co2_production',
                transform: 'value * 1e-6' }
            ],
            rows: { require: 'emissions_sector' }
          }
        end

        let(:node_bar) do
          instance_double(
            'Qernel::Node',
            emissions?: true,
            node_api: instance_double(
              'Qernel::NodeApi::EnergyApi', key: :bar, direct_reporting_emissions_co2_production: nil
            )
          )
        end

        before do
          allow(sectors).to receive(:node_index).with(:energy).and_return({ pair => [:bar] })
          allow(gql.future.graph).to receive(:node).with(:bar).and_return(node_bar)
        end

        it 'renders an empty string without evaluating the transform' do
          expect(serializer.data[1]).to eq(['bar', ''])
        end
      end
    end
  end

  context 'when given an unknown sector mapping column' do
    let(:gql) { Scenario.default.gql }
    let(:serializer) { described_class.new(config, gql, period: :future) }

    context 'as a "rows: require:" reference' do
      let(:config) do
        {
          schema: [{ name: 'Key', type: 'node_attribute', value: 'key' }],
          rows: { require: 'impossible' }
        }
      end

      it 'raises at construction, naming the invalid reference and the valid columns' do
        expect { serializer }.to raise_error(
          Export::ConfiguredCSVSerializer::UnknownMappingColumnError,
          /impossible.*Valid columns.*emissions_sector/m
        )
      end
    end

    context 'as a "sector_mapping" column value' do
      let(:config) do
        {
          schema: [
            { name: 'Sector', type: 'sector_mapping', value: 'impossible' }
          ],
          rows: { require: 'emissions_sector' }
        }
      end

      it 'raises at construction, naming the invalid reference and the valid columns' do
        expect { serializer }.to raise_error(
          Export::ConfiguredCSVSerializer::UnknownMappingColumnError,
          /impossible.*Valid columns.*emissions_sector/m
        )
      end
    end

    context 'as a "rows: order_by:" reference' do
      let(:config) do
        {
          schema: [{ name: 'Key', type: 'node_attribute', value: 'key' }],
          rows: { require: 'emissions_sector', order_by: 'impossible' }
        }
      end

      it 'raises at construction, naming the invalid reference and the valid columns' do
        expect { serializer }.to raise_error(
          Export::ConfiguredCSVSerializer::UnknownMappingColumnError,
          /impossible.*Valid columns.*emissions_sector/m
        )
      end
    end
  end
end
