require 'spec_helper'

RSpec.describe 'Api::V3::ScenarioUsers', type: :request, api: true do
  let(:user) { create(:user) }
  let!(:scenario) { create(:scenario, user: user) }

  describe 'GET index' do
    it 'returns invalid token without a proper access token' do
      get "/api/v3/scenarios/#{scenario.id}/users", as: :json

      expect(response.status).to be(401)
    end

    # A user should have a token with the scenario:delete scope before its allowed
    # to do anything through this endpoint, because this is what equals to the 'owner' role.
    it 'returns forbidden for a token without the proper access scope' do
      get "/api/v3/scenarios/#{scenario.id}/users", as: :json,
        headers: access_token_header(user, :read)

      expect(response).to have_http_status(:forbidden)
    end

    context 'with a proper token and scope' do
      before do
        get "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete)
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns a list of all users' do
        expect(JSON.parse(response.body)).to include(
          a_hash_including('user_id' => user.id, 'user_email' => nil, 'role' => 'scenario_owner')
        )
      end
    end
  end

  describe 'POST /api/v3/scenarios/:id/users' do
    let(:json) { JSON.parse(response.body) }

    context 'with proper params' do
      let(:user_viewer) { create(:user, email: 'viewer@test.com') }

      before do
        user_viewer

        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { user_email: 'viewer@test.com', role: 'scenario_viewer' },
              { user_email: 'collaborator@test.com', role: 'scenario_collaborator' },
              { user_email: 'owner@test.com', role: 'scenario_owner' }
            ]
          }
      end

      it 'returns success' do
        expect(response).to have_http_status(:created)
      end

      it 'adds the given users to the scenario' do
        expect(json).to contain_exactly(
          a_hash_including('user_id' => nil, 'user_email' => 'viewer@test.com', 'role' => 'scenario_viewer', 'role_id' => 1, 'scenario_id' => scenario.id),
          a_hash_including('user_id' => nil, 'user_email' => 'collaborator@test.com', 'role' => 'scenario_collaborator', 'role_id' => 2, 'scenario_id' => scenario.id),
          a_hash_including('user_id' => nil, 'user_email' => 'owner@test.com', 'role' => 'scenario_owner', 'role_id' => 3, 'scenario_id' => scenario.id)
        )
      end
    end

    context 'with missing role information' do
      before do
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_email: 'viewer@test.com' }]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['viewer@test.com']).to include('role_id')
      end
    end

    context 'with incorrect email' do
      before do
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_email: 'viewer', role: :scenario_collaborator }]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['viewer']).to include('user_email')
      end
    end

    context 'with duplicate user params' do
      before do
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { user_email: 'viewer@test.com', role: 'scenario_viewer' },
              { user_email: 'viewer@test.com', role: 'scenario_collaborator' },
            ]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['viewer@test.com']).to include('duplicate')
      end
    end

    context 'when the user was already present on the scenario' do
      let(:user_viewer) { create(:user, email: 'viewer@test.com') }

      before do
        create(
          :scenario_user, scenario: scenario, user: user_viewer,
          role_id: User::ROLES.key(:scenario_viewer)
        )
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { user_id: user_viewer.id, role: 'scenario_viewer' }
            ]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['']).to include('base')
      end
    end
  end

  describe 'PUT /api/v3/scenarios/:id/users' do
    let(:json) { JSON.parse(response.body) }

    context 'with proper params' do
      let(:user_2) { create(:user) }
      let(:user_3) { create(:user) }

      before do
        create(:scenario_user,
          scenario: scenario, user: user_2,
          role_id: User::ROLES.key(:scenario_viewer)
        )
        create(:scenario_user,
          scenario: scenario, user: user_3,
          role_id: User::ROLES.key(:scenario_collaborator)
        )

        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { user_id: user_2.id, role: 'scenario_owner' },
              { user_id: user_3.id, role: 'scenario_viewer' },
            ]
          }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the role for the given user' do
        expect(JSON.parse(response.body)).to include(
          a_hash_including('user_id' => user_2.id, 'user_email' => nil, 'role' => 'scenario_owner'),
          a_hash_including('user_id' => user_3.id, 'user_email' => nil, 'role' => 'scenario_viewer')
        )
      end
    end

    context 'when downgrading the only owner' do
      before do
        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_id: user.id, role: 'scenario_viewer' }]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['']).to include(
          'base'
        )
      end
    end

    context 'with a non-existing scenario' do
      before do
        put "/api/v3/scenarios/#{scenario.id - 10}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { user_id: 999, role: 'scenario_collaborator' },
            ]
          }
      end

      it 'returns 404: not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error' do
        expect(json['errors']).to include('Scenario not found')
      end
    end

    context 'with a non-existing user id' do
      before do
        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { user_id: 999, role: 'scenario_collaborator' },
            ]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['999']).to include(
          'Scenario user not found'
        )
      end
    end

    context 'with a missing role' do
      let(:user_2) { create(:user) }

      before do
        create(:scenario_user,
          scenario: scenario, user: user_2,
          role_id: User::ROLES.key(:scenario_viewer)
        )

        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_id: user_2.id }]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['']).to include('role_id')
      end
    end
  end

  describe 'DELETE /api/v3/scenarios/:id/users' do
    let(:json) { JSON.parse(response.body) }

    context 'with proper params' do
      let(:user_2) { create(:user) }
      let(:user_3) { create(:user) }

      before do
        create(:scenario_user,
          scenario: scenario, user: user_2,
          role_id: User::ROLES.key(:scenario_viewer)
        )
        create(:scenario_user,
          scenario: scenario, user: user_3,
          role_id: User::ROLES.key(:scenario_collaborator)
        )

        delete "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_id: user_2.id }, { user_id: user_3.id }]
          }
      end

      it 'returns OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'removes the given users' do
        expect(
          scenario.scenario_users.count
        ).to be(1)
      end
    end

    context 'with a non-existing user id' do
      before do
        delete "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_id: 999 }]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['999']).to include(
          'Scenario user not found'
        )
      end
    end

    context 'when destroying the last owner' do
      before do
        delete "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ user_id: user.id }]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(json['errors']['']).to include(
          'base'
        )
      end
    end
  end
end
