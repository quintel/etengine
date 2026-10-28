# frozen_string_literal: true

require 'spec_helper'

describe 'Legacy PAT fallback with API v3' do
  let(:user) { create(:user) }
  let(:scenario) { create(:scenario, private: true, bound: true) }
  let(:myetm) do
    instance_double(
      Faraday::Connection, request: nil, response: nil, options: Faraday::RequestOptions.new
    )
  end
  let(:user_pat) { pat_header }

  def grant(level)
    instance_double(Faraday::Response, body: { 'data' => { level => [scenario.id] } })
  end

  def pat_header(actor = user)
    { 'Authorization' => "Bearer etm_#{generate_jwt(actor, scopes: match_scopes(:write))}" }
  end

  def show(headers = user_pat)
    get("/api/v3/scenarios/#{scenario.id}", headers:)
  end

  def update(headers = user_pat)
    params = { scenario: { keep_compatible: true } }
    put("/api/v3/scenarios/#{scenario.id}", params:, headers:)
  end

  def copy(source_key)
    params = { scenario: { source_key => scenario.id } }
    post('/api/v3/scenarios', params:, headers: user_pat)
  end

  before do
    Settings.scenario_access_grants_only = true
    Rails.cache.clear
    allow(Faraday).to receive(:new).and_yield(myetm).and_return(myetm)
    allow(myetm).to receive(:get).and_return(grant('read'))
  end

  after { Settings.scenario_access_grants_only = false }

  context 'when MyETM grants write' do
    before { allow(myetm).to receive(:get).and_return(grant('write')) }

    it 'reads the private Session' do
      show

      expect(response).to have_http_status(:ok)
    end

    it 'writes to the Session' do
      update

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when MyETM grants read' do
    it 'reads the private Session' do
      show

      expect(response).to have_http_status(:ok)
    end

    it 'refuses a write' do
      update

      expect(response).to have_http_status(:not_found)
    end

    it 'copies the private Session' do
      copy(:scenario_id)

      expect(response).to have_http_status(:ok)
    end

    it 'copies the private Session as a preset' do
      copy(:preset_scenario_id)

      expect(response).to have_http_status(:ok)
    end
  end

  it 'refuses a copy when MyETM grants nothing' do
    allow(myetm).to receive(:get).and_return(grant('none'))
    copy(:scenario_id)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'asks MyETM with the PAT' do
    show

    expect(myetm).to have_received(:request).with(:authorization, 'Bearer', start_with('etm_'))
  end

  it 'asks MyETM about this Session in this engine version' do
    show

    expect(myetm).to have_received(:get)
      .with("/api/v2/legacy_grants/#{Settings.version_tag}/#{scenario.id}")
  end

  it 'gives up on MyETM after a short timeout' do
    show

    expect(myetm.options.to_hash.slice(:timeout, :open_timeout))
      .to eq(timeout: 2, open_timeout: 2)
  end

  it 'fails closed when MyETM fails or is slow' do
    allow(myetm).to receive(:get).and_raise(Faraday::TimeoutError)
    show

    expect(response).to have_http_status(:not_found)
  end

  it 'asks MyETM once within the cache window' do
    2.times { show }

    expect(myetm).to have_received(:get).once
  end

  it 'keeps the answer for 30 minutes' do
    allow(Rails.cache).to receive(:fetch).and_call_original
    show

    expect(Rails.cache).to have_received(:fetch).with(anything, expires_in: 30.minutes)
  end

  it 'asks MyETM again after a failure' do
    allow(myetm).to receive(:get).and_raise(Faraday::ConnectionFailed, 'down')
    show
    allow(myetm).to receive(:get).and_return(grant('read'))
    show

    expect(response).to have_http_status(:ok)
  end

  context 'when MyETM refuses the PAT' do
    before do
      allow(myetm).to receive(:get).and_raise(Faraday::UnauthorizedError)
      allow(Rails.cache).to receive(:write).and_call_original
    end

    it 'fails closed' do
      show

      expect(response).to have_http_status(:not_found)
    end

    it 'never asks MyETM about that PAT again' do
      2.times { show }

      expect(myetm).to have_received(:get).once
    end

    it 'remembers the refusal for 2 hours' do
      show
      pat = user_pat['Authorization'].delete_prefix('Bearer ')
      key = ['legacy-pat', Digest::SHA256.hexdigest(pat), :revoked]

      expect(Rails.cache).to have_received(:write).with(key, true, expires_in: 2.hours)
    end
  end

  describe 'reporting to Sentry' do
    let(:scope) { instance_double(Sentry::Scope, set_user: nil, set_extras: nil) }

    before { allow(Sentry).to receive(:capture_message).and_yield(scope) }

    it 'reports each answer from MyETM once' do
      2.times { show }

      expect(Sentry).to have_received(:capture_message).with('Legacy PAT request', level: :info).once
    end

    it 'names the user' do
      show

      expect(scope).to have_received(:set_user).with(id: user.id, email: user.email)
    end

    it 'does not report a failed lookup' do
      allow(myetm).to receive(:get).and_raise(Faraday::TimeoutError)
      show

      expect(Sentry).not_to have_received(:capture_message)
    end
  end

  describe 'requests that dont take this path' do
    it 'skips a session token' do
      show(access_token_header(user, :write))

      expect(Faraday).not_to have_received(:new)
    end

    it 'skips a PAT in the session cookie' do
      cookies[Identity.config.session_cookie_name] =
        "etm_#{generate_jwt(user, scopes: match_scopes(:write))}"
      show({})

      expect(Faraday).not_to have_received(:new)
    end

    it 'skips a PAT in the access_token param' do
      access_token = user_pat['Authorization'].delete_prefix('Bearer ')
      get("/api/v3/scenarios/#{scenario.id}", params: { access_token: })

      expect(Faraday).not_to have_received(:new)
    end

    it 'skips everything with grants only off' do
      Settings.scenario_access_grants_only = false
      show

      expect(Faraday).not_to have_received(:new)
    end

    it 'skips an unbound Session' do
      scenario.update!(bound: false, creator_id: user.id)
      show

      expect(Faraday).not_to have_received(:new)
    end

    it 'skips an admin' do
      show(pat_header(create(:user, admin: true)))

      expect(Faraday).not_to have_received(:new)
    end

    it 'skips a batch of Sessions' do
      get("/api/v3/scenarios/#{scenario.id},#{scenario.id}/batch", headers: pat_header)

      expect(Faraday).not_to have_received(:new)
    end
  end
end
