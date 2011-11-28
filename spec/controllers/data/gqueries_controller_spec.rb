require 'spec_helper'

describe Data::GqueriesController do
  render_views
  
  let!(:admin) { FactoryGirl.create :admin }
  let!(:gquery) { FactoryGirl.create :gquery }
  let!(:graph) { FactoryGirl.create :graph }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do
    it "should be successful" do
      get :index, :blueprint_id =>'latest', :region_code => 'nl'
      response.should render_template(:index)
    end
  end

  describe "GET new" do
    it "should be successful" do
      get :new, :blueprint_id =>'latest', :region_code => 'nl'
      response.should render_template(:new)
    end
  end

  describe "GET show" do
    it "should be successful" do
      get :show, :id => gquery.id, :blueprint_id =>'latest', :region_code => 'nl'
      response.should render_template(:show)
    end
  end

  describe "GET edit" do
    it "should be successful" do
      get :edit, :id => gquery.id, :blueprint_id =>'latest', :region_code => 'nl'
      response.should render_template(:edit)
    end
  end
  
  describe "GET key" do
    it "should be successful" do
      get :key, :blueprint_id =>'latest', :region_code => 'nl', :key => gquery.key
      assigns(:gquery).should == gquery
      response.should render_template(:show)
    end
    
    it "should redirect to the search page if the gquery can't be found" do
      get :key, :blueprint_id =>'latest', :region_code => 'nl', :key => 'foobar'
      response.should redirect_to data_gqueries_path(:blueprint_id =>'latest', :region_code => 'nl', :q => 'foobar')
    end
  end
end
