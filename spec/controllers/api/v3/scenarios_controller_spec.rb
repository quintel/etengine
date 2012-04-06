require 'spec_helper'

describe Api::V3::ScenariosController do
  before do
    @scenario = Factory :scenario
  end

  describe "GET show.json" do
    it "should return a scenario info" do
      get :show, :id => @scenario.id, :format => :json
      response.should be_success
      assigns(:scenario).should == @scenario
    end
  end
end
