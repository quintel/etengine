require 'spec_helper'

describe Inspect::GqueriesController, :etsource_fixture do
  render_views

  let(:admin) { FactoryBot.create :admin }
  let(:owner) { FactoryBot.create :user }
  let(:scenario) { FactoryBot.create(:scenario, user: owner) }
  let!(:gquery) { Gquery.get('bar_demand') }

  describe "GET index" do
    context 'when admin is logged in' do
      before do
        sign_in(admin)
      end

      it "should be successful" do
        get :index, params: { :api_scenario_id => scenario.id }
        expect(response).to render_template(:index)
      end
    end

    context 'when scenario owner is logged in' do
      before do
        sign_in(owner)
      end

      it "should be successful" do
        get :index, params: { :api_scenario_id => scenario.id }
        expect(response).to render_template(:index)
      end
    end

    context 'when a user is logged in and the scenario is private' do

      before do
        sign_in(create(:user))
        scenario.private = true
      end

      it "should be unsuccessful" do
        pending('Wait for merge multi user support')

        get :index, params: { :api_scenario_id => scenario.id }
        expect(response).not_to render_template(:index)
      end
    end
  end

  describe "GET show" do
    context 'when admin is logged in' do
      before do
        sign_in(admin)
      end

      it "should be successful" do
        get :show, params: { :id => gquery.key, :api_scenario_id => scenario.id }
        expect(response).to render_template(:show)
      end
    end

    context 'when scenario owner is logged in' do
      before do
        sign_in(owner)
      end

      it "should be successful" do
        get :show, params: { :id => gquery.key, :api_scenario_id => scenario.id }
        expect(response).to render_template(:show)
      end
    end
  end

  #TODO: Remove this test - it is a test test
  describe Api::V3::GqueriesController, type: :request do
    # let(:user) { create(:user) }
    # let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: 'public scenarios:read') }
    # let(:token_header) { { 'Authorization' => "Bearer #{access_token.token}" } }
    let(:user) { create(:user) }
    let(:token_header) { access_token_header(user, :read) }

    before do
      # mock_token = OpenStruct.new(sub: user.id.to_s, scopes: 'public scenarios:read')
      # allow(ETEngine::TokenDecoder).to receive(:decode).and_return(mock_token)
      get '/api/v3/scenarios', headers: token_header
    end

    it 'includes Authorization header' do
      decoded_token = ETEngine::TokenDecoder.decode(token_header['Authorization'].split(' ').last)
      expect(decoded_token[:sub]).to eq(user.id.to_s)
    end
  end
end
