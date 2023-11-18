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
        expect(response.body).to eq(
          [
            { id: user.id, email: nil, role: 'scenario_owner' }
          ].to_json
        )
      end
    end
  end

  describe 'POST /api/v3/scenarios/:id/users' do
    context 'with proper params' do
      before do
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { id: nil, email: 'viewer@test.com', role: 'scenario_viewer' },
              { id: nil, email: 'collaborator@test.com', role: 'scenario_collaborator' },
              { id: nil, email: 'owner@test.com', role: 'scenario_owner' }
            ]
          }
      end

      it 'returns success' do
        expect(response).to have_http_status(:created)
      end

      it 'adds the given users to the scenario' do
        expect(response.body).to eq(
          [
            { id: nil, email: 'viewer@test.com', role: 'scenario_viewer' },
            { id: nil, email: 'collaborator@test.com', role: 'scenario_collaborator' },
            { id: nil, email: 'owner@test.com', role: 'scenario_owner' }
          ].to_json
        )
      end
    end

    context 'with malformed user params' do
      before do
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { id: nil, email: 'viewer@test.com' }
            ]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(response.body).to eq(
          { id: nil, email: 'viewer@test.com', error: 'role_id is invalid.' }.to_json
        )
      end
    end

    context 'with duplicate user params' do
      before do
        post "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { id: nil, email: 'viewer@test.com', role: 'scenario_viewer' },
              { id: nil, email: 'viewer@test.com', role: 'scenario_collaborator' },
            ]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(response.body).to eq(
          {
            id: nil, role: 'scenario_collaborator', email: 'viewer@test.com',
            error: 'A user with this ID or email already exists for this scenario'
          }.to_json
        )
      end
    end
  end

  describe 'PUT /api/v3/scenarios/:id/users' do
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
              { id: user_2.id, role: 'scenario_owner' },
              { id: user_3.id, role: 'scenario_viewer' },
            ]
          }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the role for the given user' do
        expect(response.body).to eq(
          [
            { id: user_2.id, email: nil, role: 'scenario_owner' },
            { id: user_3.id, email: nil, role: 'scenario_viewer' },
          ].to_json
        )
      end
    end

    context 'with a duplicate user id' do
      let(:user_2) { create(:user) }

      before do
        create(:scenario_user,
          scenario: scenario, user: user_2,
          role_id: User::ROLES.key(:scenario_viewer)
        )

        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { id: user_2.id, role: 'scenario_owner' },
              { id: user_2.id, role: 'scenario_viewer' },
            ]
          }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the user to the last stated role' do
        expect(response.body).to eq(
          [
            { id: user_2.id, email: nil, role: 'scenario_viewer' }
          ].to_json
        )
      end
    end

    context 'with a non-existing user id' do
      before do
        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { id: 999, role: 'scenario_collaborator' },
            ]
          }
      end

      it 'returns 404: not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error' do
        expect(response.body).to eq(
          { id: 999, role: 'scenario_collaborator', error: 'Scenario user not found' }.to_json
        )
      end
    end

    context 'with a missing role' do
      before do
        put "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [
              { id: 999 },
            ]
          }
      end

      it 'returns 422: unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an error' do
        expect(response.body).to eq(
          { id: 999, error: 'No role given to update with.' }.to_json
        )
      end
    end
  end

  describe 'DELETE /api/v3/scenarios/:id/users' do
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
            scenario_users: [{ id: user_2.id }, { id: user_3.id }]
          }
      end

      it 'returns OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns an empty response body' do
        expect(response.body).to eq('')
      end

      it 'removes the given users' do
        expect(
          scenario.scenario_users.count
        ).to be(1)
      end
    end

    context 'with duplicate user ids' do
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
            scenario_users: [{ id: user_2.id }, { id: user_2.id }] # User 2, twice
          }
      end

      it 'returns 422: unprocessable_entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns an empty response body' do
        expect(response.body).to eq(
          {'error': 'Duplicate user ids found in request, please revise.'}.to_json
        )
      end
    end

    context 'with a non-existing user id' do
      before do
        delete "/api/v3/scenarios/#{scenario.id}/users", as: :json,
          headers: access_token_header(user, :delete),
          params: {
            scenario_users: [{ id: 999 }]
          }
      end

      it 'returns 404: not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an empty response body' do
        expect(response.body).to eq(
          {'error': 'Could not find user(s) with id: 999'}.to_json
        )
      end
    end
  end
end


