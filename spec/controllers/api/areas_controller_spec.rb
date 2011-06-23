require 'spec_helper'

describe Api::AreasController do
  let!(:area) { Factory :area}
  
  describe "GET index.xml" do
    it "should return all areas" do
      get :index, :format => :xml
      response.should be_success
      assigns(:areas).should == [area]
    end
  end
    
  describe "GET show.xml" do
    it "should return an area" do
      get :show, :id => area.id, :format => :xml
      response.should be_success
      assigns(:area).should == area
    end
  end
end