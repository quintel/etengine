require 'spec_helper'

describe Api::V3::ScenariosController do
  let(:scenario) { Factory :scenario }

  describe "GET show.json" do
    it "should return a scenario info" do
      get :show, :id => scenario.id, :format => :json
      response.should be_success
      assigns(:scenario).should == scenario
    end
  end
  
  describe "GET sandbox" do
    it "should return result of a gquerie" do
      get :sandbox, :id => scenario.id,:gql => 'SUM(1,2)', :format => :json
      response.should be_success
      parsed_body = JSON.parse(response.body)
      parsed_body["present_value"].to_i.should eql(3)
      parsed_body["future_value"].to_i.should eql(3)
      assigns(:scenario).should == scenario
    end
  end

  describe "GET templates" do
    it "should return the homepage scenarios" do
      get :templates
      response.should be_success
      assigns(:presets).should == Preset.all
    end
  end

  describe "PUT scenario" do
    before do
      @scenario = Factory :scenario, :user_values => {:foo => 123.0}
    end

    it "should reset parameters" do
      put :update, :id => @scenario.id, :reset => true
      response.should be_success
      @scenario.reload.user_values.should == {}
    end

    it "should merge parameters" do
      put :update, :id => @scenario.id, :scenario => {:user_values => {:bar => 456.0}}
      response.should be_success
      @scenario.reload.user_values.to_set.should == {'foo' => 123.0, 'bar' => 456.0}.to_set
    end

    it "should merge parameters resetting old values when needed" do
      put :update, :id => @scenario.id, :scenario => {:user_values => {:bar => 456.0}}, :reset => true
      response.should be_success
      @scenario.reload.user_values.to_set.should == {'bar' => 456.0}.to_set
    end

    it "should update parameters" do
      put :update, :id => @scenario.id, :scenario => {:user_values => {:foo => 456.0}}
      response.should be_success
      @scenario.reload.user_values.to_set.should == {'foo' => 456.0}.to_set
    end
  end
end
