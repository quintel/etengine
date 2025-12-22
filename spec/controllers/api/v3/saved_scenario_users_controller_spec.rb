# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::SavedScenarioUsersController, type: :controller do
  let(:user) { create(:user) }
  let(:scenario) { create(:scenario, user:) }
  let(:idp_client) { instance_double(Faraday::Connection) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:current_ability).and_return(Ability.new(user))
    allow(controller).to receive(:authorize!).and_return(true)
    allow(controller).to receive(:my_etm_client).and_return(idp_client)

    request.headers.merge!(access_token_header(user, :write))
  end

  describe 'GET #index' do
    let(:users_data) do
      [
        { 'user_id' => user.id, 'user_email' => nil, 'role' => 'scenario_owner' }
      ]
    end

    context 'with a valid saved scenario ID' do
      before do
        response_double = instance_double(Faraday::Response, body: users_data)
        allow(idp_client).to receive(:get)
          .with('/api/v1/saved_scenarios/1/users')
          .and_return(response_double)

        get :index, params: { saved_scenario_id: 1 }
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the list of users' do
        parsed = JSON.parse(response.body)
        expect(parsed).to eq(users_data)
      end
    end

    context 'with an invalid saved scenario ID' do
      before do
        allow(idp_client).to receive(:get).and_raise(Faraday::ResourceNotFound)
        get :index, params: { saved_scenario_id: 999 }
      end

      it 'responds with not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        saved_scenario_id: 1,
        saved_scenario_users: [
          { user_email: 'viewer@test.com', role: 'scenario_viewer' },
          { user_email: 'collaborator@test.com', role: 'scenario_collaborator' }
        ]
      }
    end

    let(:created_users) do
      [
        { 'user_id' => nil, 'user_email' => 'viewer@test.com', 'role' => 'scenario_viewer' },
        { 'user_id' => nil, 'user_email' => 'collaborator@test.com',
          'role' => 'scenario_collaborator' }
      ]
    end

    context 'when successful' do
      before do
        response_double = instance_double(Faraday::Response, body: created_users)
        allow(idp_client).to receive(:post)
          .with('/api/v1/saved_scenarios/1/users', hash_including(saved_scenario_users: kind_of(Array)))
          .and_return(response_double)

        post :create, params:
      end

      it 'responds with created status' do
        expect(response).to have_http_status(:created)
      end

      it 'returns the created users' do
        parsed = JSON.parse(response.body)
        expect(parsed).to eq(created_users)
      end
    end

    context 'when MyETM returns validation errors' do
      let(:error_response) do
        {
          body: { 'errors' => { 'viewer@test.com' => ['user_email'] } },
          status: 422
        }
      end

      before do
        error = Faraday::UnprocessableEntityError.new(error_response)
        allow(error).to receive(:response).and_return(error_response)
        allow(idp_client).to receive(:post).and_raise(error)

        post :create, params:
      end

      it 'responds with unprocessable entity status' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns the error message' do
        parsed = JSON.parse(response.body)
        expect(parsed['errors']).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let(:params) do
      {
        saved_scenario_id: 1,
        saved_scenario_users: [
          { user_id: user.id, role: 'scenario_viewer' }
        ]
      }
    end

    let(:updated_users) do
      [
        { 'user_id' => user.id, 'user_email' => nil, 'role' => 'scenario_viewer' }
      ]
    end

    context 'when successful' do
      before do
        response_double = instance_double(Faraday::Response, body: updated_users)
        allow(idp_client).to receive(:put)
          .with('/api/v1/saved_scenarios/1/users', hash_including(saved_scenario_users: kind_of(Array)))
          .and_return(response_double)

        put :update, params:
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated users' do
        parsed = JSON.parse(response.body)
        expect(parsed).to eq(updated_users)
      end
    end

    context 'with a non-existing user' do
      let(:error_response) do
        {
          body: { 'errors' => { '999' => ['Scenario user not found'] } },
          status: 422
        }
      end

      before do
        error = Faraday::UnprocessableEntityError.new(error_response)
        allow(error).to receive(:response).and_return(error_response)
        allow(idp_client).to receive(:put).and_raise(error)

        put :update, params: { saved_scenario_id: 1, saved_scenario_users: [{ user_id: 999 }] }
      end

      it 'responds with unprocessable entity status' do
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:params) do
      {
        saved_scenario_id: 1,
        saved_scenario_users: [
          { user_id: 123 }
        ]
      }
    end

    let(:deleted_users) do
      [
        { 'user_id' => 123, 'user_email' => nil, 'role' => 'scenario_viewer' }
      ]
    end

    context 'when successful' do
      before do
        request_stub = instance_double(Faraday::Request, headers: {}, 'body=': nil)
        response_double = instance_double(Faraday::Response, body: deleted_users)

        allow(idp_client).to receive(:delete)
          .with('/api/v1/saved_scenarios/1/users')
          .and_yield(request_stub)
          .and_return(response_double)

        delete :destroy, params:
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the deleted users' do
        parsed = JSON.parse(response.body)
        expect(parsed).to eq(deleted_users)
      end
    end

    context 'when trying to delete the last owner' do
      let(:error_response) do
        {
          body: { 'errors' => { '' => ['base'] } },
          status: 422
        }
      end

      before do
        error = Faraday::UnprocessableEntityError.new(error_response)
        allow(error).to receive(:response).and_return(error_response)
        allow(idp_client).to receive(:delete).and_raise(error)

        delete :destroy, params:
      end

      it 'responds with unprocessable entity status' do
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
