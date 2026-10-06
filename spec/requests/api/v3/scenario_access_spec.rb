# frozen_string_literal: true

require 'spec_helper'

describe 'Scenario access granted by MyETM with API v3' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:owner) { create(:user) }
  let(:scenario) { create(:scenario, user: owner, private: true) }
  let(:user) { create(:user) }

  def show(scenario_access:, actor: user)
    get(
      "/api/v3/scenarios/#{scenario.id}",
      headers: access_token_header(actor, :read, scenario_access:)
    )
  end

  def update(scenario_access:, actor: user)
    put(
      "/api/v3/scenarios/#{scenario.id}",
      params: { scenario: { keep_compatible: true } },
      headers: access_token_header(actor, :write, scenario_access:)
    )
  end

  context 'with grants off' do
    it 'ignores a read grant' do
      show(scenario_access: { 'read' => [scenario.id] })

      expect(response).to have_http_status(:not_found)
    end

    it 'ignores a write grant' do
      update(scenario_access: { 'write' => [scenario.id] })

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with grants on' do
    before { Settings.scenario_access_grants = true }
    after { Settings.scenario_access_grants = false }

    it 'reads with a read grant and no scenario_users row' do
      show(scenario_access: { 'read' => [scenario.id] })

      expect(response).to have_http_status(:ok)
    end

    it 'reads with a write grant' do
      show(scenario_access: { 'write' => [scenario.id] })

      expect(response).to have_http_status(:ok)
    end

    it 'writes with a write grant and no scenario_users row' do
      update(scenario_access: { 'write' => [scenario.id] })

      expect(response).to have_http_status(:ok)
    end

    it 'does not write with a read grant' do
      update(scenario_access: { 'read' => [scenario.id] })

      expect(response).to have_http_status(:not_found)
    end

    it 'adds nothing from a grant naming another Session' do
      show(scenario_access: { 'write' => [scenario.id + 1] })

      expect(response).to have_http_status(:not_found)
    end

    it 'refuses a token without the claim, as today' do
      show(scenario_access: nil)

      expect(response).to have_http_status(:not_found)
    end

    it 'still reads from a scenario_users row without a grant' do
      show(scenario_access: nil, actor: owner)

      expect(response).to have_http_status(:ok)
    end

    it 'does not delete with a write grant' do
      delete(
        "/api/v3/scenarios/#{scenario.id}",
        headers: access_token_header(user, :delete, scenario_access: { 'write' => [scenario.id] })
      )

      expect(response).to have_http_status(:not_found)
    end
  end
end
