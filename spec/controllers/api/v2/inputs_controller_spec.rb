require 'spec_helper'

describe Api::V2::InputsController do
  before do
    Factory :scenario
  end

  describe "GET index.xml" do
    it "should return all inputs" do
      get :index, :format => :xml
      response.should be_success
    end
  end
end