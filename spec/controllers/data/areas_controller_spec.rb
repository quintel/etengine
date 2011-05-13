require 'spec_helper'

describe Data::AreasController do
  let(:admin) { Factory :admin }
  let(:area) { Factory :area }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do    
    it "should be successful" do
      get :index
      response.should render_template(:index)
    end
  end
  
  describe "GET show" do    
    it "should be successful" do
      get :show, :id => area.id
      response.should render_template(:show)
    end
  end
end
