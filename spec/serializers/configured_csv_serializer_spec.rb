# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfiguredCSVSerializer do
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
end
