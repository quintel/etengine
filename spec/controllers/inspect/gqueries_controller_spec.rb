require 'spec_helper'

describe Inspect::GqueriesController, :etsource_fixture do
  render_views

  let(:admin) { FactoryBot.create :admin }
  let(:scenario) { FactoryBot.create(:scenario) }
  let!(:gquery) { Gquery.get('bar_demand') }

  before do
    sign_in(admin)
  end

  describe "GET index" do
    it "should be successful" do
      get :index, params: { :api_scenario_id => scenario.id }
      expect(response).to render_template(:index)
    end
  end

  describe "GET show" do
    it "should be successful" do
      get :show, params: { :id => gquery.key, :api_scenario_id => scenario.id }
      expect(response).to render_template(:show)
    end
  end
end
