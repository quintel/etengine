require 'spec_helper'

describe Data::AreasController do
  let(:admin) { FactoryBot.create :admin }

  before do
    sign_in(admin)
    FactoryBot.create :scenario
  end

  describe "GET show" do
    it "should be successful" do
      get :show, params: { :api_scenario_id => 'latest' }
      expect(response).to render_template(:show)
    end
  end
end
