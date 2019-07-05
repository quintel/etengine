require 'spec_helper'

describe Inspect::AreasController do
  let(:admin) { FactoryBot.create :admin }
  let(:scenario) { FactoryBot.create :scenario }

  before do
    sign_in(admin)
  end

  describe "GET show" do
    it "should be successful" do
      get :show, params: { :api_scenario_id => scenario.id }
      expect(response).to render_template(:show)
    end
  end
end
