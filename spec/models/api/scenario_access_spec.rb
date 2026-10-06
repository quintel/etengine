# frozen_string_literal: true

RSpec.describe Api::ScenarioAccess do
  describe 'reading a claim' do
    subject(:access) { described_class.new('write' => [1, 3], 'read' => [2]) }

    it 'writes the Sessions granted write' do
      expect(access.writable).to contain_exactly(1, 3)
    end

    it 'reads the Sessions granted read or write' do
      expect(access.readable).to contain_exactly(1, 2, 3)
    end
  end

  describe 'the token contract with MyETM' do
    include ActiveSupport::Testing::TimeHelpers

    let(:contract) { JSON.parse(Rails.root.join('spec/fixtures/token_contract.json').read) }
    let(:claims) { Identity::TokenDecoder.decode(contract['granted_token']) }
    let(:access) { described_class.new(claims[described_class::CLAIM]) }

    around do |example|
      issuer, client_uri = Identity.config.issuer, Identity.config.client_uri
      travel_to(Time.at(contract['generated_at'])) { example.run }
    ensure
      Identity.config.issuer, Identity.config.client_uri = issuer, client_uri
    end

    before do
      Identity.config.issuer = contract['issuer']
      Identity.config.client_uri = contract['session_audience'].first
      allow(Identity::TokenDecoder).to receive(:jwk_set).and_return(contract['jwks'])
    end

    it 'reads the write grants from the token MyETM mints' do
      expect(access.writable).to eq([648_695])
    end

    it 'reads the read grants from the token MyETM mints' do
      expect(access.readable).to contain_exactly(648_695, 612_000)
    end
  end

  [
    ['no claim', nil],
    ['a claim that is not a hash', [1, 2]],
    ['a level that is not a list', { 'write' => 1 }],
    ['ids that are not integers', { 'write' => ['1'], 'read' => [nil, 2.0] }]
  ].each do |description, claim|
    it "grants nothing for #{description}" do
      access = described_class.new(claim)

      expect([access.readable, access.writable]).to eq([[], []])
    end
  end
end
