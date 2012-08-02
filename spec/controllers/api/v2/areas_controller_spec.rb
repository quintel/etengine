require 'spec_helper'

describe Api::V2::AreasController do
  before do
    Factory.create :scenario
  end

  describe "GET show.xml" do
    it "should return an area" do
      Area.stub!(:get){ {:area => 'nl'}}
      get :show, :id => 'nl', :format => :xml
      response.should be_success
    end
  end
end