require 'spec_helper'

describe Inspect::NodesController do
  let(:admin) { FactoryBot.create(:admin) }
  let(:scenario) { FactoryBot.create(:scenario) }

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
      get :show, params: { :api_scenario_id => scenario.id, :id => 'foo' }
      expect(response).to render_template(:show)
    end
  end
end
