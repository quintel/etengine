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

  describe "GET show" do
    it "should be successful" do
      get :show, :id => gquery.lookup_id, :api_scenario_id =>'latest'
      response.should render_template(:show)
    end
  end

end
