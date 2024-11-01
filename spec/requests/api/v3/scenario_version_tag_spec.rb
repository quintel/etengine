# frozen_string_literal: true

require 'spec_helper'

describe 'Scenario versions API' do

  let(:scenario) { create(:scenario, user: user) }
  let(:scenario2) { create(:scenario, user: user, preset_scenario: scenario) }

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

      let(:private_scenario) { create(:scenario, user: create(:user), private: true) }

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
          headers: access_token_header(user, :write)
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
        let(:params) { { description: message } }

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
          headers: access_token_header(user, :write)
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
          headers: access_token_header(user, :write)
        )

        scenario.reload
      end

      context 'when updating the message' do
        let(:params) { { description: message2 } }

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
        let(:params) { { user_id: create(:user).id, description: message2 } }

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
          headers: access_token_header(user, :write)
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
end
