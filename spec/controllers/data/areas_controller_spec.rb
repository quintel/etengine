require 'spec_helper'

describe Data::AreasController do
  let(:admin)     { Factory :admin }
  let!(:area)     { Factory :area, :country => 'nl' }
  let!(:graph)    { Factory :graph }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do    
    it "should be successful" do
      get :index, :blueprint_id => 'latest', :region_code => 'nl'
      response.should redirect_to(data_area_path(:id => area.id, :blueprint_id => 'latest', :region_code => 'nl'))
    end
  end
  
  describe "GET show" do    
    it "should be successful" do
      get :show, :blueprint_id => 'latest', :region_code => 'nl', :id => area.id
      response.should render_template(:show)
    end
  end
end
