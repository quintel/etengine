# frozen_string_literal: true

require 'spec_helper'

# Temporary until session handles are implemented, when this file is removed with creator_id.
describe 'APIv3 scenario creator', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  let(:user) { create(:user) }
  let(:headers) { access_token_header(user, :write) }
  let(:json) { JSON.parse(response.body) }
  let(:created) { Scenario.last }

  context 'when a signed-in user creates a scenario' do
    before do
      post '/api/v3/scenarios', headers:
    end

    it 'sets the user as the creator' do
      expect(created.creator_id).to eq(user.id)
    end

    it 'does not include the creator in the response' do
      expect(json).not_to have_key('creator_id')
    end
  end

  context 'when an anonymous caller creates a scenario' do
    before do
      post '/api/v3/scenarios'
    end

    it 'sets no creator' do
      expect(created.creator_id).to be_nil
    end
  end

  context 'when copying a scenario created by another user' do
    let(:parent) { create(:scenario, creator_id: create(:user).id) }

    before do
      post '/api/v3/scenarios', params: { scenario: { scenario_id: parent.id } }, headers:
    end

    it 'sets the caller as the creator' do
      expect(created.creator_id).to eq(user.id)
    end
  end

  context 'when creating a scenario with creator_id set' do
    let(:other_user) { create(:user) }

    before do
      post '/api/v3/scenarios', params: { scenario: { creator_id: other_user.id } }, headers:
    end

    it 'sets the caller as the creator' do
      expect(created.creator_id).to eq(user.id)
    end
  end

  context 'when updating a scenario with creator_id set' do
    let(:scenario) { create(:scenario, user:, creator_id: user.id) }
    let(:other_user) { create(:user) }

    before do
      put "/api/v3/scenarios/#{scenario.id}",
        params: { scenario: { creator_id: other_user.id } },
        headers:
    end

    it 'keeps the creator' do
      expect(scenario.reload.creator_id).to eq(user.id)
    end
  end

  context 'when interpolating a scenario created by another user' do
    let(:source) { create(:scenario, end_year: 2050, creator_id: create(:user).id) }

    before do
      post "/api/v3/scenarios/#{source.id}/interpolate", params: { end_year: 2040 }, headers:
    end

    it 'sets the caller as the creator' do
      expect(created.creator_id).to eq(user.id)
    end
  end

  context 'when merging scenarios' do
    let(:scenarios) do
      create_list(:scenario, 2, user_values: { 'grouped_input_one' => 50.0 })
    end

    before do
      post '/api/v3/scenarios/merge',
        params: { scenarios: scenarios.map { |scenario| { scenario_id: scenario.id } } },
        headers:
    end

    it 'sets the caller as the creator' do
      expect(created.creator_id).to eq(user.id)
    end
  end

  context 'when an admin loads a dump' do
    let(:user) { create(:user, admin: true) }

    before do
      post '/api/v3/scenarios/load_dump',
        params: { area_code: 'nl', end_year: 2050 },
        headers:,
        as: :json
    end

    it 'sets the admin as the creator' do
      expect(created.creator_id).to eq(user.id)
    end
  end
end
