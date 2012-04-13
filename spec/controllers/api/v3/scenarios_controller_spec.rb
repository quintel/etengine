require 'spec_helper'

describe Api::V3::ScenariosController do
  before do
    @scenario = Factory :scenario
  end

  describe "GET show.json" do
    it "should return a scenario info" do
      get :show, :id => @scenario.id, :format => :json
      response.should be_success
      assigns(:scenario).should == @scenario
    end
  end

  describe "GET templates" do
    it "should return the homepage scenarios" do
      home_scenario = Factory :scenario_visible_in_homepage
      get :templates
      response.should be_success
      assigns(:scenarios).should == [home_scenario]
    end
  end
end
