require 'spec_helper'

describe Inspect::GqueriesController, :etsource_fixture do
  render_views

  let(:admin) { FactoryBot.create :admin }
  let(:owner) { FactoryBot.create :user }
  let(:scenario) { FactoryBot.create(:scenario, user: owner) }
  let!(:gquery) { Gquery.get('bar_demand') }

  describe "GET index" do
    context 'when admin' do
      it "should be successful" do
        request.headers.merge!(access_token_header(admin, :read))
        get :index, params: { api_scenario_id: scenario.id }
        expect(response).to render_template(:index)
      end
    end

    context 'when scenario owner' do
      it "should be successful" do
        request.headers.merge!(access_token_header(owner, :read))
        get :index, params: { api_scenario_id: scenario.id }
        expect(response).to render_template(:index)
      end
    end

    context 'when the scenario is private' do
      before do
        scenario.update(private: true)
      end

      it "should be unsuccessful" do
        pending('Wait for merge multi-user support')

        request.headers.merge!(access_token_header(create(:user), :read))
        get :index, params: { api_scenario_id: scenario.id }
        expect(response).not_to render_template(:index)
      end
    end
  end

  describe "GET show" do
    context 'when admin' do
      it "should be successful" do
        request.headers.merge!(access_token_header(admin, :read))
        get :show, params: { id: gquery.key, api_scenario_id: scenario.id }
        expect(response).to render_template(:show)
      end
    end

    context 'when scenario owner' do
      it "should be successful" do
        request.headers.merge!(access_token_header(owner, :read))
        get :show, params: { id: gquery.key, api_scenario_id: scenario.id }
        expect(response).to render_template(:show)
      end
    end
  end
end
