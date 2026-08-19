# frozen_string_literal: true

require 'spec_helper'

# ETEngine authorizes a scenario from the scenario_access claim MyETM mints, alongside the legacy
# scenario_users join, behind a setting.
describe 'Scenario access grants with API v3' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  # A private scenario owned by someone else: the caller holds no scenario_users row, so only a
  # grant can authorize them.
  let(:owner) { create(:user) }
  let(:scenario) { create(:scenario, user: owner, private: true) }
  let(:user) { create(:user) }

  let(:read_grant) { { 'scenario_id' => scenario.id, 'level' => 'read' } }
  let(:write_grant) { { 'scenario_id' => scenario.id, 'level' => 'write' } }

  def show(grant:, actor: user, scopes: :read)
    get("/api/v3/scenarios/#{scenario.id}", headers: access_token_header(actor, scopes, grant:))
  end

  def update(grant:, actor: user, scopes: :write)
    put(
      "/api/v3/scenarios/#{scenario.id}",
      params: { scenario: { keep_compatible: true } },
      headers: access_token_header(actor, scopes, grant:)
    )
  end

  context 'with the setting off' do
    before { Settings.scenario_access_grants = false }

    it 'ignores the grant and refuses the caller, exactly as today' do
      show(grant: read_grant)

      expect(response).to have_http_status(:not_found)
    end

    it 'ignores a write grant too' do
      update(grant: write_grant)

      expect(response).not_to have_http_status(:ok)
    end
  end

  context 'with the setting on' do
    before { Settings.scenario_access_grants = true }
    after { Settings.scenario_access_grants = false }

    it 'authorizes a read with no scenario_users row for the caller' do
      show(grant: read_grant)

      expect(response).to have_http_status(:ok)
    end

    it 'authorizes a write from a write grant' do
      update(grant: write_grant)

      expect(response).to have_http_status(:ok)
    end

    it 'does not let a read grant write' do
      update(grant: read_grant)

      expect(response).not_to have_http_status(:ok)
    end

    it 'refuses a caller with neither grant nor join row' do
      show(grant: nil)

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses a grant naming a different scenario' do
      show(grant: { 'scenario_id' => scenario.id + 1, 'level' => 'write' })

      expect(response).to have_http_status(:not_found)
    end

    it 'still authorizes the owner, who has a join row and no grant' do
      show(actor: owner, grant: nil)

      expect(response).to have_http_status(:ok)
    end

    it 'does not authorize a read without the read scope' do
      show(grant: read_grant, scopes: :public)

      expect(response).to have_http_status(:not_found)
    end
  end
end
