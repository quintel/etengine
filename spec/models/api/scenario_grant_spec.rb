# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::ScenarioGrant do
  describe '.from_token' do
    it 'reads the scenario id and level from the claim' do
      grant = described_class.from_token('scenario_access' => {
        'scenario_id' => 648_695, 'level' => 'write'
      })

      expect([grant.scenario_id, grant.level]).to eq([648_695, 'write'])
    end

    it 'is nil when the token carries no claim' do
      expect(described_class.from_token('sub' => 1)).to be_nil
    end

    it 'is nil when the token is nil' do
      expect(described_class.from_token(nil)).to be_nil
    end

    it 'is nil when the claim names no scenario' do
      expect(described_class.from_token('scenario_access' => { 'level' => 'write' })).to be_nil
    end
  end

  describe '#write?' do
    it 'is true for a write grant' do
      expect(described_class.new(scenario_id: 1, level: 'write')).to be_write
    end

    it 'is false for a read grant' do
      expect(described_class.new(scenario_id: 1, level: 'read')).not_to be_write
    end

    # Only "write" writes, so a malformed or unexpected level can lose access, never gain it.
    it 'is false for an unrecognised level' do
      expect(described_class.new(scenario_id: 1, level: 'admin')).not_to be_write
    end
  end

  describe 'against the token MyETM actually mints' do
    include ActiveSupport::Testing::TimeHelpers

    let(:contract) do
      JSON.parse(Rails.root.join('spec/fixtures/token_contract.json').read)
    end

    let(:claims) do
      travel_to(Time.zone.at(contract['generated_at'])) do
        Identity::TokenDecoder.decode(contract['grant_token'])
      end
    end

    let(:configured) { { issuer: Identity.config.issuer, client_uri: Identity.config.client_uri } }

    before do
      configured
      Identity.config.issuer = contract['issuer']
      Identity.config.client_uri = contract['session_audience'].first
      allow(Identity::TokenDecoder).to receive(:jwk_set).and_return(contract['jwks'])
    end

    after do
      Identity.config.issuer = configured[:issuer]
      Identity.config.client_uri = configured[:client_uri]
    end

    it 'builds a grant from the claim MyETM minted' do
      grant = described_class.from_token(claims)

      expect(grant.scenario_id).to eq(contract['scenario_access']['scenario_id'])
    end

    it 'reads the level MyETM minted' do
      expect(described_class.from_token(claims).level)
        .to eq(contract['scenario_access']['level'])
    end
  end
end
