require 'spec_helper'

describe Api::ScenariosController do
  before do
    @scenario = Factory :scenario
    @homepage_scenario = Factory :scenario_visible_in_homepage
  end
  
  describe "GET index.xml" do
    it "should return all scenarios" do
      get :index, :format => :xml
      response.should be_success
      assigns(:scenarios).to_set.should == [@scenario, @homepage_scenario].to_set
    end
  end
  
  describe "GET homepage.xml" do
    it "should return the scenarios visible in homepage" do
      get :homepage, :format => :xml
      response.should be_success
      assigns(:scenarios).should == [@homepage_scenario]
    end
  end
  
  describe "GET show.xml" do
    it "should return the scenarios visible in homepage" do
      get :show, :id => @scenario.id, :format => :xml
      response.should be_success
      assigns(:scenario).should == @scenario
    end
  end
end
