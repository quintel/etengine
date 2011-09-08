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

  describe "Creating scenario from api_scenario" do
    before do
      @api_scenario = Factory(:api_scenario)
      @api_scenario.country = 'de'
      @api_scenario.save
    end

    it "should create a new scenario with values from api_scenario" do
      put :create, 'scenario' => {'title' => 'foo bar', 'api_session_id' => @api_scenario.id.to_s }

      assigns(:scenario).title.should == 'foo bar'
      assigns(:scenario).country.should == @api_scenario.country
    end
  end
end
