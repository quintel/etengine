require 'spec_helper'

describe Api::V3::ConvertersController do
  before do
    scenario = Scenario.new
    @converter = Api::V3::Converter.new('foobar', scenario)
  end

  describe "GET show.json" do
    it "should return a converter info" do
      get :show, :id => @converter.key, :format => :json
      response.should be_success
      assigns(:converter).should == @converter
    end
  end
end
