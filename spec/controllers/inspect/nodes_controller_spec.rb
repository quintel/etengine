require 'spec_helper'

RSpec.describe 'Inspect::Nodes', type: :request do
  let(:admin) { FactoryBot.create(:admin) }
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:headers) { access_token_header(admin, :delete) }

  describe 'GET /inspect/:api_scenario_id/graphs/:graph_name/nodes' do
    it 'is successful' do
      get "/inspect/#{scenario.id}/graphs/energy/nodes", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  describe 'GET /inspect/:api_scenario_id/graphs/:graph_name/nodes/:id' do
    context 'with a valid graph and node key' do
      it 'is successful' do
        get "/inspect/#{scenario.id}/graphs/energy/nodes/foo", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end

    context 'with a valid graph and invalid node key' do
      it 'renders Not Found' do
        get "/inspect/#{scenario.id}/graphs/energy/nodes/nope", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with a valid node key, but incorrect graph' do
      it 'renders Not Found' do
        get "/inspect/#{scenario.id}/graphs/molecules/nodes/foo", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with a valid node key, but illegal graph' do
      it 'renders Not Found' do
        get "/inspect/#{scenario.id}/graphs/nope/nodes/foo", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
