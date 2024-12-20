require 'spec_helper'

describe Api::V3::CollectionsController, type: :controller do
  let(:user) { create(:user) }
  let(:scenario) { create(:scenario, user: user) }
  let(:idp_client) { instance_double("ETEngine::Clients::IdpClient") }
  let(:response_body) { { 'data' => [], 'links' => {} } }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:set_current_scenario).and_return(scenario)
    allow(controller).to receive(:authorize!).and_return(true)
    allow(controller).to receive(:idp_client).and_return(idp_client)
    request.headers.merge!(access_token_header(user, :read))
  end

  describe 'GET #index' do
    before do
      allow(idp_client).to receive(:get).with(a_string_matching(%r{/api/v1/collections\?((page=1&limit=10)|(limit=10&page=1))})).and_return(double(body: response_body))
      get :index, params: { page: 1, limit: 10 }
    end

    it 'responds successfully' do
      expect(response).to have_http_status(:ok)
    end

    it 'renders the JSON response' do
      expect(JSON.parse(response.body)).to include('data', 'links')
    end
  end

  describe 'GET #show' do
    context 'with a valid ID' do
      before do
        allow(idp_client).to receive(:get).with("/api/v1/collections/1").and_return(double(body: response_body))
        get :show, params: { id: 1 }
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'renders the collection data' do
        expect(JSON.parse(response.body)).to eq(response_body)
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
    let(:params) { { title: 'New Collection', scenario_ids: [scenario.id] } }
    let(:upsert_service) { instance_double(UpsertTransitionPath) }

    before do
      allow(UpsertTransitionPath).to receive(:new).and_return(upsert_service)
    end

    context 'when successful' do
      before do
        allow(upsert_service).to receive(:call).and_return(Dry::Monads::Success([{ 'id' => 1, 'title' => 'New Collection' }]))
        post :create, params: params
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the created data' do
        expect(JSON.parse(response.body)).to include('id' => 1, 'title' => 'New Collection')
      end
    end

    context 'when failure occurs' do
      before do
        allow(upsert_service).to receive(:call).and_return(Dry::Monads::Failure(['Invalid data']))
        post :create, params: params
      end

      it 'responds with unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the errors' do
        expect(JSON.parse(response.body)).to include('errors' => ['Invalid data'])
      end
    end
  end

  describe 'PUT #update' do
    let(:params) { { id: 1, title: 'Updated Collection' } }
    let(:upsert_service) { instance_double(UpsertTransitionPath) }

    before do
      allow(UpsertTransitionPath).to receive(:new).and_return(upsert_service)
    end

    context 'when successful' do
      before do
        allow(upsert_service).to receive(:call).and_return(Dry::Monads::Success([{ 'id' => 1, 'title' => 'Updated Collection' }]))
        put :update, params: params
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the updated data' do
        expect(JSON.parse(response.body)).to include('id' => 1, 'title' => 'Updated Collection')
      end
    end

    context 'when failure occurs' do
      before do
        allow(upsert_service).to receive(:call).and_return(Dry::Monads::Failure(['Invalid data']))
        put :update, params: params
      end

      it 'responds with unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the errors' do
        expect(JSON.parse(response.body)).to include('errors' => ['Invalid data'])
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with a valid ID' do
      before do
        allow(idp_client).to receive(:delete).with("/api/v1/collections/1").and_return(double(body: response_body))
        delete :destroy, params: { id: 1 }
      end

      it 'responds successfully' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with an invalid ID' do
      before do
        allow(idp_client).to receive(:delete).and_raise(Faraday::ResourceNotFound)
        delete :destroy, params: { id: 999 }
      end

      it 'responds with not found' do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
