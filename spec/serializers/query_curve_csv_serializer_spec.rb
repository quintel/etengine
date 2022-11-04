# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QueryCurveCSVSerializer do
  let(:config) do
    [
      {
        name: 'Query one',
        query: 'query_1'
      },
      {
        name: 'Query two',
        query: 'query_2'
      }
    ]
  end

  let(:query_1) { Gquery.new(query: '[1, 2] * 4380', unit: 'curve') }
  let(:query_2) { Gquery.new(query: '[3, 4] * 4380', unit: 'curve') }

  let(:serializer) { described_class.new(config, Scenario.default.gql, 'export.csv') }

  before do
    allow(Gquery).to receive(:get).with('query_1').and_return(query_1)
    allow(Gquery).to receive(:get).with('query_2').and_return(query_2)
  end

  # ------------------------------------------------------------------------------------------------

  context 'when given a valid config' do
    it 'includes the CSV headers' do
      expect(serializer.to_csv_rows[0]).to eq(['Time', 'Query one', 'Query two'])
    end

    it 'includes the first row' do
      expect(serializer.to_csv_rows[1]).to eq(['2050-01-01 00:00', 1, 3])
    end

    it 'includes the second row' do
      expect(serializer.to_csv_rows[2]).to eq(['2050-01-01 01:00', 2, 4])
    end
  end
end
