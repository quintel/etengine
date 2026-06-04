# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::SavedScenariosController, type: :controller do
  let(:user)     { create(:user) }
  let(:scenario) { create(:scenario, user: user) }
  let(:idp_client) { instance_double(Faraday::Connection) }
  let(:response_body) { { 'data' => [], 'links' => {} } }

  before do
    allow(controller).to receive_messages(current_user: user, current_ability: Ability.new(user), authorize!: true, my_etm_client: idp_client)

    request.headers.merge!(access_token_header(user, :read))
  end

  describe 'GET #index' do
    before do
      # The controller queries: /api/v1/saved_scenarios?page=1&limit=10
      allow(idp_client).to receive(:get)
        .with(a_string_matching(%r{/api/v1/saved_scenarios\?((page=1&limit=10)|(limit=10&page=1))}))
        .and_return(double(body: response_body))

      get :index, params: { page: 1, limit: 10 }
    end

    it 'responds successfully' do
      expect(response).to have_http_status(:ok)
    end

    it 'renders the JSON response' do
      parsed = response.parsed_body
      expect(parsed).to include('data', 'links')
    end
  end

  describe 'GET #show' do
    context 'with a valid ID' do
      let(:saved_scenario_data) { { 'scenario_id' => scenario.id } }

      before do
        allow(idp_client).to receive(:get)
          .with('/api/v1/saved_scenarios/1')
          .and_return(double(body: saved_scenario_data))

        get :show, params: { id: 1 }
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'renders the saved scenario data' do
        parsed = response.parsed_body
        expect(parsed).to include('scenario_id' => scenario.id)
      end
    end

    context 'with an invalid ID' do
      before do
        allow(idp_client).to receive(:get).and_raise(Faraday::ResourceNotFound)
        get :show, params: { id: 999 }
      end

      it 'responds with not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        saved_scenario: {
          scenario_id: scenario.id,
          title: 'New Saved Scenario',
          description: 'A test scenario',
          private: false
        }
      }
    end

    let(:create_service) { instance_double(CreateSavedScenario) }

    before do
      allow(CreateSavedScenario).to receive(:new).and_return(create_service)
    end

    context 'when successful' do
      let(:created_data) { { 'scenario_id' => scenario.id, 'title' => 'New Saved Scenario' } }

      before do
        allow(create_service).to receive(:call)
          .with(params: hash_including('scenario_id'),
            ability: instance_of(Ability),
            client: idp_client)
          .and_return(Dry::Monads::Success([created_data, nil]))

        post :create, params: params
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the created data' do
        parsed = response.parsed_body
        expect(parsed).to include('title' => 'New Saved Scenario', 'scenario_id' => scenario.id)
      end
    end

    context 'when failure occurs' do
      before do
        allow(create_service).to receive(:call)
          .and_return(Dry::Monads::Failure(['Invalid data']))

        post :create, params: params
      end

      it 'responds with unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns the errors' do
        parsed = response.parsed_body
        expect(parsed).to include('errors' => ['Invalid data'])
      end
    end
  end

  describe 'PUT #update' do
    let(:params) { { id: 1, saved_scenario: { title: 'Updated Saved Scenario' } } }
    let(:update_service) { instance_double(UpdateSavedScenario) }

    before do
      allow(UpdateSavedScenario).to receive(:new).and_return(update_service)
    end

    context 'when successful' do
      let(:updated_data) { { 'scenario_id' => scenario.id, 'title' => 'Updated Saved Scenario' } }

      before do
        allow(update_service).to receive(:call)
          .with(id: '1', params: hash_including('title'), ability: instance_of(Ability), client: idp_client)
          .and_return(Dry::Monads::Success([updated_data, nil]))

        put :update, params: params
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated data' do
        parsed = response.parsed_body
        expect(parsed).to include('title' => 'Updated Saved Scenario', 'scenario_id' => scenario.id)
      end
    end

    context 'when failure occurs' do
      before do
        allow(update_service).to receive(:call)
          .and_return(Dry::Monads::Failure(['Invalid data']))

        put :update, params: params
      end

      it 'responds with unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns the errors' do
        parsed = response.parsed_body
        expect(parsed).to include('errors' => ['Invalid data'])
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:delete_service) { instance_double(DeleteSavedScenario) }

    before do
      allow(DeleteSavedScenario).to receive(:new).and_return(delete_service)
    end

    context 'with a valid ID' do
      before do
        allow(delete_service).to receive(:call)
          .with(id: '1', client: idp_client)
          .and_return(Dry::Monads::Success([response_body, nil]))

        delete :destroy, params: { id: 1 }
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the response data' do
        parsed = response.parsed_body
        expect(parsed).to include('data', 'links')
      end
    end

    context 'with an invalid ID' do
      before do
        allow(delete_service).to receive(:call)
          .and_raise(Faraday::ResourceNotFound)

        delete :destroy, params: { id: 999 }
      end

      it 'responds with not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT #discard' do
    let(:discard_service) { instance_double(DiscardSavedScenario) }

    before do
      allow(DiscardSavedScenario).to receive(:new).and_return(discard_service)
    end

    context 'with a valid ID' do
      before do
        allow(discard_service).to receive(:call)
          .with(id: '1', client: idp_client)
          .and_return(Dry::Monads::Success([{ 'message' => 'Scenario discarded successfully' },
                                            nil]))

        put :discard, params: { id: 1 }
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the response data' do
        parsed = response.parsed_body
        expect(parsed).to include('message' => 'Scenario discarded successfully')
      end
    end

    context 'with an invalid ID' do
      before do
        allow(discard_service).to receive(:call)
          .and_raise(Faraday::ResourceNotFound)

        put :discard, params: { id: 999 }
      end

      it 'responds with not found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'authorization check' do
      it 'calls authorize! with destroy permission' do
        allow(discard_service).to receive(:call)
          .with(id: '1', client: idp_client)
          .and_return(Dry::Monads::Success([{ 'message' => 'Scenario discarded successfully' },
                                            nil]))

        expect(controller).to receive(:authorize!).with(:destroy, Scenario)

        put :discard, params: { id: 1 }
      end
    end

    context 'integration test without service mocking' do
      before do
        allow(DiscardSavedScenario).to receive(:new).and_call_original
      end

      context 'with successful discard' do
        before do
          allow(idp_client).to receive(:put)
            .with('/api/v1/saved_scenarios/1/discard')
            .and_return(double(body: { 'message' => 'Scenario discarded successfully' }))

          put :discard, params: { id: 1 }
        end

        it 'responds successfully' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns the response data' do
          parsed = response.parsed_body
          expect(parsed).to include('message' => 'Scenario discarded successfully')
        end
      end

      context 'with validation errors from MyETM' do
        before do
          error_response = {
            body: { 'errors' => { 'scenario' => ['already discarded'] } },
            status: 422
          }
          error = Faraday::UnprocessableEntityError.new(error_response)
          allow(error).to receive(:response).and_return(error_response)
          allow(idp_client).to receive(:put).and_raise(error)

          put :discard, params: { id: 1 }
        end

        it 'responds with unprocessable entity' do
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'returns the error messages' do
          parsed = response.parsed_body
          expect(parsed['errors']).to eq({ 'scenario' => ['already discarded'] })
        end
      end
    end
  end
end
