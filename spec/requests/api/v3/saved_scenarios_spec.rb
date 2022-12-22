# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Saved scenarios API' do
  let(:user) { create(:user) }

  def stub_etmodel_request(url, method: :get, body: nil)
    conn = Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        stub.public_send(method, url, body) do |_env|
          yield
        end
      end
    end

    allow(ETEngine::Auth).to receive(:etmodel_client).and_return(conn)
  end

  context 'when fetching a single saved scenario' do
    context 'when the saved scenario and scenario exist' do
      let(:scenario) { create(:scenario, owner: user, area_code: 'nl') }

      before do
        stub_etmodel_request('/api/v1/saved_scenarios/1') do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id' => 1,
              'scenario_id' => scenario.id,
              'title' => 'My saved scenario',
              'description' => '',
              'area_code' => 'nl',
              'end_year' => 2050,
              'created_at' => '2022-12-18T11:25:04.000Z',
              'updated_at' => '2022-12-18T11:25:04.000Z',
              'user' => {
                'id' => user.id,
                'name' => user.name
              }
            }
          ]
        end

        get '/api/v3/saved_scenarios/1', headers: access_token_header(user, 'scenarios:read')
      end

      it 'is successful' do
        expect(response).to be_successful
      end

      it 'includes the saved scenario data' do
        expect(JSON.parse(response.body)).to include(
          'id' => 1,
          'scenario_id' => scenario.id,
          'title' => 'My saved scenario'
        )
      end

      it 'includes the scenario in the response' do
        expect(JSON.parse(response.body)['scenario']).to include(
          'id' => scenario.id,
          'area_code' => 'nl'
        )
      end
    end

    context 'when the saved scenario exists but the scenario does not' do
      before do
        stub_etmodel_request('/api/v1/saved_scenarios/1') do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id' => 1,
              'scenario_id' => 1,
              'title' => 'My saved scenario',
              'description' => '',
              'area_code' => 'nl',
              'end_year' => 2050,
              'created_at' => '2022-12-18T11:25:04.000Z',
              'updated_at' => '2022-12-18T11:25:04.000Z',
              'user' => {
                'id' => user.id,
                'name' => user.name
              }
            }
          ]
        end

        get '/api/v3/saved_scenarios/1', headers: access_token_header(user, 'scenarios:read')
      end

      it 'is successful' do
        expect(response).to be_successful
      end

      it 'includes the saved scenario data' do
        expect(JSON.parse(response.body)).to include(
          'id' => 1,
          'scenario_id' => 1,
          'title' => 'My saved scenario'
        )
      end

      it 'has no data for the scenario' do
        expect(JSON.parse(response.body)['scenario']).to be_nil
      end
    end

    context 'when the saved scenario exists but the scenario is not accessible' do
      let(:scenario) { create(:scenario, owner: create(:user), private: true) }

      before do
        stub_etmodel_request('/api/v1/saved_scenarios/1') do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id' => 1,
              'scenario_id' => scenario.id,
              'title' => 'My saved scenario',
              'description' => '',
              'area_code' => 'nl',
              'end_year' => 2050,
              'created_at' => '2022-12-18T11:25:04.000Z',
              'updated_at' => '2022-12-18T11:25:04.000Z',
              'user' => {
                'id' => user.id,
                'name' => user.name
              }
            }
          ]
        end

        get '/api/v3/saved_scenarios/1', headers: access_token_header(user, 'scenarios:read')
      end

      it 'is successful' do
        expect(response).to be_successful
      end

      it 'includes the saved scenario data' do
        expect(JSON.parse(response.body)).to include(
          'id' => 1,
          'scenario_id' => scenario.id,
          'title' => 'My saved scenario'
        )
      end

      it 'has no data for the scenario' do
        expect(JSON.parse(response.body)['scenario']).to be_nil
      end
    end

    context 'when the saved scenario does not exist' do
      before do
        stub_etmodel_request('/api/v1/saved_scenarios/1') do
          raise Faraday::ResourceNotFound
        end

        get '/api/v3/saved_scenarios/1', headers: access_token_header(user, 'scenarios:read')
      end

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ------------------------------------------------------------------------------------------------

  context 'when creating a saved scenario' do
    context 'when the scenario exists' do
      let(:scenario) { create(:scenario, owner: user) }
      let(:params) do
        {
          title: 'My saved scenario',
          description: 'My scenario description',
          scenario_id: scenario.id
        }
      end

      before do
        stub_etmodel_request(
          '/api/v1/saved_scenarios',
          method: :post,
          body: params.merge(
            area_code: scenario.area_code,
            end_year: scenario.end_year
          )
        ) do
          [
            200,
            { 'Content-Type' => 'application/json' },
            params.merge(id: 1).stringify_keys
          ]
        end

        post '/api/v3/saved_scenarios',
          as: :json,
          params:,
          headers: access_token_header(user, :write)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the saved scenario data' do
        expect(JSON.parse(response.body)).to include(params.stringify_keys.merge('id' => 1))
      end
    end

    context 'when missing the title' do
      let(:scenario) { create(:scenario, owner: user) }

      before do
        stub_etmodel_request('/api/v1/saved_scenarios', method: :post) do
          raise stub_faraday_422('title' => ['is missing'])
        end

        post '/api/v3/saved_scenarios',
          as: :json,
          params: {
            description: 'My scenario description',
            scenario_id: scenario.id
          },
          headers: access_token_header(user, :write)
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the saved scenario data' do
        expect(JSON.parse(response.body)).to eq('errors' => { 'title' => ['is missing'] })
      end
    end

    context 'when the scenario is not accessible' do
      let(:scenario) { create(:scenario, owner: create(:user), private: true) }

      before do
        post '/api/v3/saved_scenarios',
          as: :json,
          params: {
            title: 'My saved scenario',
            description: 'My scenario description',
            scenario_id: scenario.id
          },
          headers: access_token_header(user, :write)
      end

      it 'responds with 422 Unprocesable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the saved scenario data' do
        expect(JSON.parse(response.body)['errors']).to include(
          'scenario_id' => ['does not exist']
        )
      end
    end

    context 'when the scenario does not exist' do
      before do
        post '/api/v3/saved_scenarios',
          as: :json,
          params: {
            title: 'My saved scenario',
            description: 'My scenario description',
            scenario_id: -1
          },
          headers: access_token_header(user, :write)
      end

      it 'responds with 422 Unprocesable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the saved scenario data' do
        expect(JSON.parse(response.body)['errors']).to include(
          'scenario_id' => ['does not exist']
        )
      end
    end
  end

  # ------------------------------------------------------------------------------------------------

  context 'when updating a saved scenario' do
    context 'when the scenario exists' do
      let(:scenario) { create(:scenario, owner: user) }

      let(:params) do
        {
          title: 'My saved scenario',
          description: 'My scenario description',
          scenario_id: scenario.id
        }
      end

      before do
        stub_etmodel_request(
          '/api/v1/saved_scenarios/123',
          method: :put,
          body: params.merge(
            area_code: scenario.area_code,
            end_year: scenario.end_year
          )
        ) do
          [
            200,
            { 'Content-Type' => 'application/json' },
            params.merge(id: 1).stringify_keys
          ]
        end

        put '/api/v3/saved_scenarios/123',
          as: :json,
          params:,
          headers: access_token_header(user, :write)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the saved scenario data' do
        expect(JSON.parse(response.body)).to include(params.stringify_keys.merge('id' => 1))
      end
    end

    context 'when the saved scenario is not accessible' do
      let(:scenario) { create(:scenario, owner: user) }

      let(:params) do
        {
          title: 'My saved scenario',
          description: 'My scenario description',
          scenario_id: scenario.id
        }
      end

      before do
        stub_etmodel_request(
          '/api/v1/saved_scenarios/123',
          method: :put,
          body: params.merge(
            area_code: scenario.area_code,
            end_year: scenario.end_year
          )
        ) do
          raise Faraday::ResourceNotFound
        end

        put '/api/v3/saved_scenarios/123',
          as: :json,
          params:,
          headers: access_token_header(user, :write)
      end

      it 'responds with 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns the saved scenario data' do
        expect(JSON.parse(response.body)['errors']).to include('Not found')
      end
    end
  end

  # ------------------------------------------------------------------------------------------------

  context 'when deleting a saved scenario' do
    context 'when the saved scenario exists' do
      before do
        stub_etmodel_request('/api/v1/saved_scenarios/123', method: :delete) do
          [200, { 'Content-Type' => 'application/json' }, {}]
        end

        delete '/api/v3/saved_scenarios/123',
          as: :json,
          headers: access_token_header(user, :delete)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the access token lacks the scenarios:delete scope' do
      before do
        stub_etmodel_request('/api/v1/saved_scenarios/123', method: :delete) do
          [200, { 'Content-Type' => 'application/json' }, {}]
        end

        delete '/api/v3/saved_scenarios/123',
          as: :json,
          headers: access_token_header(user, :write)
      end

      it 'returns 403 Forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the saved scenario is inaccessible' do
      before do
        stub_etmodel_request('/api/v1/saved_scenarios/123', method: :delete) do
          raise Faraday::ResourceNotFound
        end

        delete '/api/v3/saved_scenarios/123',
          as: :json,
          headers: access_token_header(user, :delete)
      end

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
