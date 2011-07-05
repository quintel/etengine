require 'spec_helper'

describe Data::ConvertersController do
  let!(:admin) { Factory :admin }
  let!(:graph) { FactoryGirl.create :graph }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do
    it "should be successful" do
      get :index, :blueprint_id => 'latest', :region_code => 'nl'
      response.should render_template(:index)
    end
  end
end
