require 'spec_helper'

describe Data::AreasController do
  let(:admin) { FactoryGirl.create :admin }

  before do
    login_as(admin)
    FactoryGirl.create :scenario
  end

  describe "GET show" do
    it "should be successful" do
      get :show, :api_scenario_id => 'latest'
      response.should render_template(:show)
    end
  end
end
