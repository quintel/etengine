# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscardSavedScenario do
  let(:result) do
    described_class.new.call(id: 123, client:)
  end

  context 'when the scenario is discarded in MyETM' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.put('/api/v1/saved_scenarios/123/discard') do
            [200, { 'Content-Type' => 'application/json' }, { 'message' => 'Scenario discarded successfully' }]
          end
        end
      end
    end

    it 'returns a Success' do
      expect(result).to be_success
    end

    it 'returns the response data' do
      expect(result.value!).to eq({ 'message' => 'Scenario discarded successfully' })
    end
  end

  context 'when the scenario is inaccessible in MyETM' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.put('/api/v1/saved_scenarios/123/discard') do
            raise Faraday::ResourceNotFound
          end
        end
      end
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'returns an error' do
      expect(result.failure).to eq(ServiceResponse.not_found)
    end
  end
end
