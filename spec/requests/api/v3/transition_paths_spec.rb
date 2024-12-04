# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'transition paths API' do
  let(:user) { create(:user) }

  def stub_etmodel_request(url, method: :get, body: nil)
    conn = Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        stub.public_send(method, url, body) do |_env|
          yield
        end
      end
    end

    allow(ETEngine::ClientConnector).to receive(:client_app_client).and_return(conn)
  end

  pending 'when fetching a single transition path' do
    # TODO: Debug the 404 error occurring when fetching a transition path
    # Potential issues:
    # - Stub might not be correctly set up
    # - etmodel client may be incorrectly set up
    # - same issues throughout this spec
    context 'when the transition path exists' do
      before do
        stub_etmodel_request('/api/v1/transition_paths/1') do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id' => 1,
              'scenario_ids' => [12, 34],
              'title' => 'My transition path',
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

        get '/api/v3/transition_paths/1', headers: access_token_header(user, :read)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'includes the transition path data' do
        expect(JSON.parse(response.body)).to include(
          'id' => 1,
          'scenario_ids' => [12, 34],
          'title' => 'My transition path'
        )
      end
    end

    context 'when the transition path does not exist' do
      before do
        stub_etmodel_request('/api/v1/transition_paths/1') do
          raise Faraday::ResourceNotFound
        end

        get '/api/v3/transition_paths/1', headers: access_token_header(user, 'scenarios:read')
      end

      it 'returns a 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ------------------------------------------------------------------------------------------------

  pending 'when creating a transition path' do
    context 'when the scenarios exist' do
      let(:scenario) { create(:scenario, user: user) }

      let(:params) do
        {
          title: 'My transition path',
          scenario_ids: [scenario.id]
        }
      end

      before do
        stub_etmodel_request(
          '/api/v1/transition_paths',
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

        post '/api/v3/transition_paths',
          as: :json,
          params:,
          headers: access_token_header(user, :write)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the transition path data' do
        expect(JSON.parse(response.body)).to include(params.stringify_keys.merge('id' => 1))
      end
    end

    context 'when missing the title' do
      let(:scenario) { create(:scenario, user: user) }

      before do
        stub_etmodel_request('/api/v1/transition_paths', method: :post) do
          raise stub_faraday_422('title' => ['is missing'])
        end

        post '/api/v3/transition_paths',
          as: :json,
          params: { scenario_ids: [scenario.id] },
          headers: access_token_header(user, :write)
      end

      it 'responds with 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the error' do
        expect(JSON.parse(response.body)).to eq('errors' => { 'title' => ['is missing'] })
      end
    end

    context 'when a scenario is not accessible' do
      let(:scenario) { create(:scenario, user: create(:user), private: true) }

      before do
        post '/api/v3/transition_paths',
          as: :json,
          params: {
            title: 'My transition path',
            scenario_ids: [scenario.id]
          },
          headers: access_token_header(user, :write)
      end

      it 'responds with 422 Unprocesable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the transition path data' do
        expect(JSON.parse(response.body)['errors']).to include(
          'scenario_ids' => { scenario.id.to_s => ['does not exist'] }
        )
      end
    end

    pending 'when a scenario does not exist' do
      before do
        post '/api/v3/transition_paths',
          as: :json,
          params: {
            title: 'My transition path',
            scenario_ids: [-1]
          },
          headers: access_token_header(user, :write)
      end

      it 'responds with 422 Unprocesable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the transition path data' do
        expect(JSON.parse(response.body)['errors']).to include(
          'scenario_ids' => { '-1' => ['does not exist'] }
        )
      end
    end
  end

  # # ------------------------------------------------------------------------------------------------

  pending 'when updating a transition path' do
    context 'when the scenarios exist' do
      let(:scenario) { create(:scenario, user: user) }

      let(:params) do
        {
          title: 'My transition path',
          scenario_ids: [scenario.id]
        }
      end

      before do
        stub_etmodel_request(
          '/api/v1/transition_paths/123',
          method: :put,
          body: params.merge(
            area_code: scenario.area_code,
            end_year: scenario.end_year
          )
        ) do
          [
            200,
            { 'Content-Type' => 'application/json' },
            params.merge(id: 123).stringify_keys
          ]
        end

        put '/api/v3/transition_paths/123',
          as: :json,
          params:,
          headers: access_token_header(user, :write)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the transition path data' do
        expect(JSON.parse(response.body)).to include(params.stringify_keys.merge('id' => 123))
      end
    end

    context 'when the transition path is not accessible' do
      let(:scenario) { create(:scenario, user: user) }

      let(:params) do
        {
          title: 'My transition path',
          scenario_ids: [scenario.id]
        }
      end

      before do
        stub_etmodel_request(
          '/api/v1/transition_paths/123',
          method: :put,
          body: params.merge(
            area_code: scenario.area_code,
            end_year: scenario.end_year
          )
        ) do
          raise Faraday::ResourceNotFound
        end

        put '/api/v3/transition_paths/123',
          as: :json,
          params:,
          headers: access_token_header(user, :write)
      end

      it 'responds with 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns the transition path data' do
        expect(JSON.parse(response.body)['errors']).to include('Not found')
      end
    end
  end

  # # ------------------------------------------------------------------------------------------------

  pending 'when deleting a transition path' do
    context 'when the transition path exists' do
      before do
        stub_etmodel_request('/api/v1/transition_paths/123', method: :delete) do
          [200, { 'Content-Type' => 'application/json' }, {}]
        end

        delete '/api/v3/transition_paths/123',
          as: :json,
          headers: access_token_header(user, :delete)
      end

      it 'is successful' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the access token lacks the scenarios:delete scope' do
      before do
        stub_etmodel_request('/api/v1/transition_paths/123', method: :delete) do
          [200, { 'Content-Type' => 'application/json' }, {}]
        end

        delete '/api/v3/transition_paths/123',
          as: :json,
          headers: access_token_header(user, :write)
      end

      it 'returns 403 Forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the transition path is inaccessible' do
      before do
        stub_etmodel_request('/api/v1/transition_paths/123', method: :delete) do
          raise Faraday::ResourceNotFound
        end

        delete '/api/v3/transition_paths/123',
          as: :json,
          headers: access_token_header(user, :delete)
      end

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
