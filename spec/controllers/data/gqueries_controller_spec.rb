require 'spec_helper'

describe Data::GqueriesController do
  render_views
  
  let!(:admin) { FactoryGirl.create :admin }
  let!(:gquery) { Gquery.all.first }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do
    it "should be successful" do
      get :index, :api_scenario_id =>'latest'
      response.should render_template(:index)
    end
  end

  describe "GET new" do
    it "should be successful" do
      get :new, :api_scenario_id =>'latest'
      response.should render_template(:new)
    end
  end

  describe "GET show" do
    it "should be successful" do
      get :show, :id => gquery.lookup_id, :api_scenario_id =>'latest'
      response.should render_template(:show)
    end
  end
  
  describe "GET key" do
    it "should be successful" do
      get :key, :api_scenario_id =>'latest', :key => gquery.key
      assigns(:gquery).should == gquery
      response.should render_template(:show)
    end
    
    it "should redirect to the search page if the gquery can't be found" do
      get :key, :api_scenario_id =>'latest', :key => 'foobar'
      response.should redirect_to data_gqueries_path(:api_scenario_id =>'latest', :q => 'foobar')
    end
  end
end
