require 'spec_helper'

describe Inspect::NodesController do
  let(:admin) { FactoryBot.create(:admin) }
  let(:scenario) { FactoryBot.create(:scenario) }

  before do
    sign_in(admin)
  end

  describe 'GET index' do
    it 'is successful' do
      get :index, params: { graph_name: 'energy', api_scenario_id: scenario.id }
      expect(response).to render_template(:index)
    end
  end

  describe 'GET show' do
    context 'with a valid graph and node key' do
      it 'is successful' do
        get :show, params: { api_scenario_id: scenario.id, graph_name: 'energy', id: 'foo' }
        expect(response).to render_template(:show)
      end
    end

    context 'with a valid graph and invalid node key' do
      it 'renders Not Found' do
        get :show, params: { api_scenario_id: scenario.id, graph_name: 'energy', id: 'nope' }
        expect(response).to be_not_found
      end
    end

    context 'with a valid node key, but incorrect graph' do
      it 'renders Not Found' do
        get :show, params: { api_scenario_id: scenario.id, graph_name: 'molecules', id: 'foo' }
        expect(response).to be_not_found
      end
    end

    context 'with n valid node key, but illegal graph' do
      it 'renders Not Found' do
        get :show, params: { api_scenario_id: scenario.id, graph_name: 'nope', id: 'foo' }
        expect(response).to be_not_found
      end
    end
  end
end
