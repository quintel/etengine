# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteSavedScenario do
  let(:result) do
    described_class.new.call(id: 123, client:)
  end

  context 'when the scenario is deleted in ETModel' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.delete('/api/v1/saved_scenarios/123') do
            [200, { 'Content-Type' => 'application/json' }, {}]
          end
        end
      end
    end

    it 'returns a Success' do
      expect(result).to be_success
    end

    it 'returns the response data' do
      expect(result.value!).to eq({})
    end
  end

  context 'when the scenario is inaccessible in ETModel' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.delete('/api/v1/saved_scenarios/123') do
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
