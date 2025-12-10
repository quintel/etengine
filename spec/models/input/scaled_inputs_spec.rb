# frozen_string_literal: true

require 'spec_helper'

describe Input::ScaledInputs, :etsource_fixture do
  let(:scenario) { create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:cache) { Input::Cache.new }
  let(:scaled_inputs) { described_class.new(cache, scenario.gql) }

  before do
    scenario.create_scaler!(
      area_attribute: 'present_number_of_residences',
      value: 500_000
    )
    Rails.cache.clear
  end

  describe '#read_many' do
    it 'responds to read_many method' do
      expect(scaled_inputs).to respond_to(:read_many)
    end

    it 'accepts scenario and inputs array parameters' do
      input = Input.all.first
      skip 'No inputs available' unless input
      expect { scaled_inputs.read_many(scenario, [input]) }.not_to raise_error
    end

    it 'returns a hash' do
      input = Input.all.first
      skip 'No inputs available' unless input
      result = scaled_inputs.read_many(scenario, [input])
      expect(result).to be_a(Hash)
    end

    it 'returns scaled values with required keys' do
      input = Input.all.first
      skip 'No inputs available' unless input

      result = scaled_inputs.read_many(scenario, [input])

      values = result[input.key]
      expect(values).to include(:min, :max, :default)
    end

    it 'handles multiple inputs' do
      inputs = Input.all.take(2)
      skip 'Not enough inputs available' unless inputs.length >= 2

      result = scaled_inputs.read_many(scenario, inputs)

      expect(result.keys.length).to eq(2)
    end

    it 'returns empty hash for empty input array' do
      result = scaled_inputs.read_many(scenario, [])
      expect(result).to eq({})
    end
  end
end
