require 'spec_helper'

describe Api::V3::ScenariosController do
  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:scenarios) { 5.times.map { FactoryGirl.create(:scenario) } }

  before do
    Input.stub(:records).and_return({
      'foo' => FactoryGirl.build(:input, key: :foo, priority: 0),
      'bar' => FactoryGirl.build(:input, key: :bar, priority: 0)
    })

    Input.stub(:all).and_return(Input.records.values)
  end

  describe "GET show.json" do
    it "should return a scenario info" do
      get :show, :id => scenario.id, :format => :json
      response.should be_success
      assigns(:scenario).should == scenario
    end
  end

  describe "GET batch.json" do
    it "should return the info of multiple scenarios" do
      get :batch, :id => [scenarios.map(&:id)].join(','), :format => :json
      response.should be_success

      assigns(:scenarios).should be_a(Array)

      assigns(:scenarios).each do |scenario|
        expect(scenario).to be_a(Api::V3::ScenarioPresenter)
      end
    end
  end

  describe "GET templates" do
    it "should return the homepage scenarios" do
      get :templates
      response.should be_success
    end

    it "should not include in_start_menu=false scenarios" do
      get :templates

      parsed = JSON.parse(response.body)

      expect(parsed.length).to eq(Preset.visible.length)
      expect(parsed.map { |v| v['title'] }).to_not include('Hidden Preset')
    end
  end

  describe "PUT scenario" do
    before do
      @scenario = FactoryGirl.create(:scenario, :user_values => {'foo' => 23.0})
    end

    it "should reset parameters" do
      put :update, :id => @scenario.id, :reset => true
      response.should be_success
      @scenario.reload.user_values.should == {}
    end

    it "should merge parameters" do
      put :update, :id => @scenario.id, :scenario => {:user_values => {'bar' => 56.0}}
      response.should be_success
      @scenario.reload.user_values.to_set.should == {'foo' => 23.0, 'bar' => 56.0}.to_set
    end

    it "should merge parameters resetting old values when needed" do
      put :update, :id => @scenario.id, :scenario => {:user_values => {'bar' => 56.0}}, :reset => true
      response.should be_success
      @scenario.reload.user_values.to_set.should == {'bar' => 56.0}.to_set
    end

    it "should update parameters" do
      put :update, :id => @scenario.id, :scenario => {:user_values => {'foo' => 56.0}}
      response.should be_success
      @scenario.reload.user_values.to_set.should == {'foo' => 56.0}.to_set
      @scenario.reload.user_values.should == {'foo' => 56.0}
    end

    it "shouldn't update end_year" do
      put :update, :id => @scenario.id, :scenario => {:end_year => 2050}
      response.should be_success
      @scenario.reload.end_year.should == 2040
    end

    it "shouldn't update start_year" do
      expect {
        put :update, :id => @scenario.id, :scenario => {:start_year => 2009}
      }.to_not change { @scenario.reload.start_year }

      response.should be_success
    end

    it "shouldn't update area" do
      put :update, :id => @scenario.id, :scenario => {:area_code => 'de'}
      response.should be_success
      @scenario.reload.area_code.should == 'nl'
    end

  end
end
