# frozen_string_literal: true

require 'spec_helper'

describe 'Scenario versions API' do

  # Access is determined solely by the token's scenario_access grant. The scenarios are bound (saved
  # in MyETM) so that the grant is the only route to access beyond what is public.
  let(:scenario) { create(:scenario, bound: true) }
  let(:scenario2) { create(:scenario, bound: true, preset_scenario: scenario) }
  let(:write_header) do
    access_token_header(user, :write, scenario_access: scenario_grant(write: [scenario.id]))
  end

  let(:message) { 'First version!' }
  let(:message2) { 'Second version!' }

  let(:user) { create(:user) }
  let(:json) { JSON.parse(response.body) }

  describe 'index' do
    context 'when all scenarios have a version tag' do
      before do
        create(:scenario_version_tag, scenario: scenario, user: user, description: message)
        create(:scenario_version_tag, scenario: scenario2, user: user, description: message2)

        get "/api/v3/scenarios/versions",
          params: { scenarios: [scenario.id, scenario2.id] },
          headers: access_token_header(create(:user), :read)
      end

      it 'is successful' do
        expect(response.status).to eq(200)
      end

      it 'includes the first scenarios version tag description' do
        expect(json[scenario.id.to_s]['description']).to eq(message)
      end

      it 'includes the first scenarios version tag user' do
        expect(json[scenario.id.to_s]['user_id']).to eq(user.id)
      end

      it 'includes the first scenarios version tag update time' do
        expect(json[scenario.id.to_s].keys).to include('last_updated_at')
      end


      it 'includes the second scenarios version tag' do
        expect(json[scenario2.id.to_s]).to include(
           {
            'description' => message2,
            'user_id' => user.id
          }
        )
      end
    end

    context 'when one scenario does not have a version tag' do
      before do
        create(:scenario_version_tag, scenario: scenario, user: user, description: message)

        get "/api/v3/scenarios/versions",
          params: { scenarios: [scenario.id, scenario2.id] },
          headers: access_token_header(create(:user), :read)
      end

      it 'is successful' do
        expect(response.status).to eq(200)
      end

      it 'includes the first scenarios version tag' do
        expect(json[scenario.id.to_s]).to include(
          {
            'description' => message,
            'user_id' => user.id
          }
        )
      end

      it 'does not include the second scenario' do
        expect(json[scenario2.id.to_s].keys).to eq(['last_updated_at'])
      end
    end

    context 'when one scenario is not owned by the user' do
      before do
        create(:scenario_version_tag, scenario: scenario, user: user, description: message)

        get "/api/v3/scenarios/versions",
          params: { scenarios: [scenario.id, private_scenario.id] },
          headers: access_token_header(create(:user), :read)
      end

      let(:private_scenario) { create(:scenario, creator_id: create(:user).id, private: true) }

      it 'is successful' do
        expect(response.status).to eq(200)
      end

      it 'includes the first scenarios version tag' do
        expect(json[scenario.id.to_s]).to include(
          {
            'description' => message,
            'user_id' => user.id
          }
        )
      end

      it 'does not include the second scenario' do
        expect(json.keys).not_to include(private_scenario.id.to_s)
      end
    end

    context 'when the token grants read access to a private scenario' do
      before do
        create(:scenario_version_tag, scenario: private_scenario, user:, description: message)

        get '/api/v3/scenarios/versions',
          params: { scenarios: [private_scenario.id] },
          headers: access_token_header(
            create(:user), :read, scenario_access: scenario_grant(read: [private_scenario.id])
          )
      end

      let(:private_scenario) { create(:scenario, bound: true, private: true) }

      it 'includes the private scenario' do
        expect(json.keys).to include(private_scenario.id.to_s)
      end
    end
  end

  describe 'show' do
    before do
      create(:scenario_version_tag, scenario: scenario, user: user, description: message)

      get "/api/v3/scenarios/#{scenario.id}/version",
        headers: access_token_header(user, :read)
    end

    it 'is successful' do
      expect(response.status).to eq(200)
    end

    it 'includes the description' do
      expect(json).to include({ 'description' => message, 'user_id' => user.id })
    end
  end

  describe 'create' do
    context 'when there was no previous record' do
      before do
        post(
          "/api/v3/scenarios/#{scenario.id}/version",
          params: params,
          headers: write_header
        )
      end

      context 'when not providing a description' do
        let(:params) { {} }

        it 'is successful' do
          expect(response.status).to eq(200)
        end

        it 'creates a version for the scenario' do
          expect(scenario.scenario_version_tag).to be_present
        end

        it 'sets the user as version tag user' do
          expect(scenario.scenario_version_tag.user).to eq(user)
        end
      end

      context 'when providing a description' do
        let(:params) { { scenario_version_tag: { description: message } } }

        it 'is successful' do
          expect(response.status).to eq(200)
        end

        it 'creates a version for the scenario' do
          expect(scenario.scenario_version_tag).to be_present
        end

        it 'sets the user as version tag user' do
          expect(scenario.scenario_version_tag.user).to eq(user)
        end

        it 'sets a message' do
          expect(scenario.scenario_version_tag.description).to eq(message)
        end
      end
    end

    context 'when there was a version already there' do
      before do
        create(:scenario_version_tag, scenario: scenario, user: user, description: message)
        post(
          "/api/v3/scenarios/#{scenario.id}/version",
          params: params,
          headers: write_header
        )
      end

      let(:params) { { description: message2 } }

      it 'is not successful' do
        expect(response.status).to eq(422)
      end

      it 'does not change message' do
        expect(scenario.scenario_version_tag.description).to eq(message)
      end

      it 'returns an error' do
        expect(json['errors']).to include('A version was already tagged')
      end
    end
  end

  describe 'update' do
    context 'with an existing version tag' do
      before do
        create(:scenario_version_tag, scenario: scenario, user: user, description: message)

        put(
          "/api/v3/scenarios/#{scenario.id}/version",
          params: params,
          headers: write_header
        )

        scenario.reload
      end

      context 'when updating the message' do
        let(:params) { { scenario_version_tag: { description: message2 } } }

        it 'is successful' do
          expect(response.status).to eq(200)
        end

        it 'creates a version for the scenario' do
          expect(scenario.scenario_version_tag).to be_present
        end

        it 'sets the user as version tag user' do
          expect(scenario.scenario_version_tag.user).to eq(user)
        end

        it 'sets a message' do
          expect(scenario.scenario_version_tag.description).to eq(message2)
        end
      end

      context 'when trying to update the user' do
        let(:params) { { user_id: create(:user).id } }

        it 'is successful' do
          expect(response.status).to eq(200)
        end

        it 'does not change the user as version tag user' do
          expect(scenario.scenario_version_tag.user).to eq(user)
        end

        it 'does not clear the message' do
          expect(scenario.scenario_version_tag.description).to eq(message)
        end
      end

      context 'when trying to update the user and the message' do
        let(:params) { {
          user_id: create(:user).id,
          scenario_version_tag: { description: message2 }
        } }

        it 'is successful' do
          expect(response.status).to eq(200)
        end

        it 'does not change the user as version tag user' do
          expect(scenario.scenario_version_tag.user).to eq(user)
        end

        it 'updates the description' do
          expect(scenario.scenario_version_tag.description).to eq(message2)
        end
      end
    end

    context 'with no pre existing version tag' do
      before do
        put(
          "/api/v3/scenarios/#{scenario.id}/version",
          params: params,
          headers: write_header
        )
      end

      let(:params) { { description: message2 } }

      it 'is not successful' do
        expect(response.status).to eq(404)
      end

      it 'returns an error' do
        expect(json['errors']).to include('Scenario version tag not found')
      end
    end
  end
  describe 'write access' do
    before { create(:scenario_version_tag, scenario:, user:, description: message) }

    def create_tag(headers)
      post "/api/v3/scenarios/#{scenario.id}/version", params: { description: message2 }, headers:
    end

    def update_tag(headers)
      put "/api/v3/scenarios/#{scenario.id}/version", params: { description: message2 }, headers:
    end

    shared_examples_for 'refused version tag writes' do |status|
      it "refuses creating with #{status}" do
        create_tag(headers)
        expect(response).to have_http_status(status)
        expect(scenario.reload.scenario_version_tag.description).to eq(message)
      end

      it "refuses updating with #{status}" do
        update_tag(headers)
        expect(response).to have_http_status(status)
        expect(scenario.reload.scenario_version_tag.description).to eq(message)
      end
    end

    context 'when the scenario is public' do
      context 'when the token has no grant for the scenario' do
        let(:headers) { access_token_header(user, :write) }

        it_behaves_like 'refused version tag writes', :forbidden
      end

      context 'when the token grants read access (viewer)' do
        let(:headers) do
          access_token_header(user, :write, scenario_access: scenario_grant(read: [scenario.id]))
        end

        it_behaves_like 'refused version tag writes', :forbidden
      end

      context 'when the token grants write access without the scenarios:write scope' do
        let(:headers) do
          access_token_header(user, :read, scenario_access: scenario_grant(write: [scenario.id]))
        end

        it_behaves_like 'refused version tag writes', :forbidden
      end
    end

    context 'when the scenario is private' do
      before { scenario.update!(private: true) }

      context 'when the token grants read access (viewer)' do
        let(:headers) do
          access_token_header(user, :write, scenario_access: scenario_grant(read: [scenario.id]))
        end

        it_behaves_like 'refused version tag writes', :not_found
      end

      context 'when the token grants write access' do
        it 'allows updating' do
          update_tag(write_header)
          expect(response).to have_http_status(:ok)
          expect(scenario.reload.scenario_version_tag.description).to eq(message2)
        end
      end
    end
  end
end
