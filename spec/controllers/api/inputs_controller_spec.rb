require 'spec_helper'

describe Api::InputsController do
  let!(:input) { Factory :input}
  
  describe "GET index.xml" do
    it "should return all inputs" do
      get :index, :format => :xml
      response.should be_success
      assigns(:inputs).should == [input]
    end
  end
    
  describe "GET show.xml" do
    it "should return an input" do
      get :show, :id => input.id, :format => :xml
      response.should be_success
      assigns(:input).should == input
    end
  end
end