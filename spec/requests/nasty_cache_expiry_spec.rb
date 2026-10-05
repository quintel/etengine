require 'spec_helper'

describe 'NastyCache expiry' do
  let(:user) { create(:user) }
  let(:cache) { NastyCache.instance }

  before do
    # Bring this process in sync with the global timestamp, then fill the local store.
    cache.initialize_request
    cache.set('stale', 'value')

    # Another process imports a new ETSource revision and broadcasts the expiry.
    cache.mark_expired!
  end

  it 'leaves the process stale until it starts a unit of work' do
    expect(cache.get('stale')).to eq('value')
  end

  it 'expires the local store on an API request' do
    # The API controllers descend from ActionController::API, so they run no ApplicationController
    # callbacks; the expiry has to come from the executor hook.
    get('/api/v3/areas/nl', headers: access_token_header(user, :read))

    expect(response).to have_http_status(:ok)
    expect(cache.get('stale')).to be_nil
  end

  it 'expires the local store outside a request' do
    Rails.application.executor.wrap { nil }

    expect(cache.get('stale')).to be_nil
  end
end
