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
end
