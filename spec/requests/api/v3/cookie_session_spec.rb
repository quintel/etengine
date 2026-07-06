# frozen_string_literal: true

require 'spec_helper'

# The shared domain JWT cookie is auto-sent to the API on same-site requests. ResourceServer reads it
# as a bearer source, so a browser request authenticates through the same path as an API bearer.
describe 'API authentication via the shared session cookie' do
  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:user) { create(:user) }
  let!(:owned) { create(:scenario, user: user, private: true, created_at: 1.minute.ago) }
  let(:jwt) { generate_jwt(user, scopes: match_scopes(:read)) }

  it 'authenticates a request carrying the JWT in the etm_session cookie' do
    get '/api/v3/scenarios', headers: { 'Cookie' => "etm_session=#{jwt}" }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['data'].pluck('id')).to include(owned.id)
  end

  it 'is unauthenticated without the cookie' do
    get '/api/v3/scenarios'

    expect(response).to have_http_status(:forbidden)
  end
end
