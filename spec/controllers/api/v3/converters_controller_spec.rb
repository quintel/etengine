require 'spec_helper'

describe Api::V3::ConvertersController do
  before do
    Gql::Gql.any_instance.stub(:prepare).and_return(true)
    scenario = Scenario.new
  end

  pending "GET show.json" do
    it "should return a converter info" do
      get :show, :id => @converter.key, :format => :json
      response.should be_success
      assigns(:converter).should == @converter
    end
  end

  describe "GET topology.json" do
    it "should return an array of converter info" do
      get :topology, :format => :json
      response.should be_success
    end
  end
end
