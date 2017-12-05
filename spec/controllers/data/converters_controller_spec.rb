require 'spec_helper'

describe Data::ConvertersController do
  let!(:admin) { FactoryBot.create(:admin) }

  before do
    sign_in(admin)
    FactoryBot.create :scenario
  end

  describe "GET index" do
    it "should be successful" do
      get :index, params: { :api_scenario_id => 'latest' }
      expect(response).to render_template(:index)
    end
  end

  describe "GET show" do
    it "should be successful" do
      get :show, params: { :api_scenario_id => 'latest', :id => 'foo' }
      expect(response).to render_template(:show)
    end
  end
end
