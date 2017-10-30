require 'spec_helper'

describe Api::V3::ScenariosController do
  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:scenarios) { 5.times.map { FactoryGirl.create(:scenario) } }

  before do
    allow(Input).to receive(:records).and_return({
      'foo' => FactoryGirl.build(:input, key: :foo, priority: 0),
      'bar' => FactoryGirl.build(:input, key: :bar, priority: 0)
    })

    allow(Input).to receive(:all).and_return(Input.records.values)
  end

  describe "GET show.json" do
    it "should return a scenario info" do
      get :show, params: { :id => scenario.id }, :format => :json
      expect(response).to be_success
      expect(assigns(:scenario)).to eq(scenario)
    end
  end

  describe "GET batch.json" do
    it "should return the info of multiple scenarios" do
      get :batch, params: { :id => [scenarios.map(&:id)].join(',') }, :format => :json
      expect(response).to be_success

      expect(assigns(:scenarios)).to be_a(Array)

      assigns(:scenarios).each do |scenario|
        expect(scenario).to be_a(Api::V3::ScenarioPresenter)
      end
    end
  end

  describe "GET templates" do
    it "should return the homepage scenarios" do
      get :templates
      expect(response).to be_success
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
      put :update, params: { :id => @scenario.id, :reset => true }
      expect(response).to be_success
      expect(@scenario.reload.user_values).to eq({})
    end

    it "should merge parameters" do
      put :update, params: {:id => @scenario.id, :scenario => {:user_values => {'bar' => 56.0}}}
      expect(response).to be_success
      expect(@scenario.reload.user_values.to_set).to eq({'foo' => 23.0, 'bar' => 56.0}.to_set)
    end

    it "should merge parameters resetting old values when needed" do
      put :update, params: {:id => @scenario.id, :scenario => {:user_values => {'bar' => 56.0}}, :reset => true}
      expect(response).to be_success
      expect(@scenario.reload.user_values.to_set).to eq({'bar' => 56.0}.to_set)
    end

    it "should update parameters" do
      put :update, params: {:id => @scenario.id, :scenario => {:user_values => {'foo' => 56.0}}}
      expect(response).to be_success
      expect(@scenario.reload.user_values.to_set).to eq({'foo' => 56.0}.to_set)
      expect(@scenario.reload.user_values).to eq({'foo' => 56.0})
    end

    it "shouldn't update end_year" do
      put :update, params: {:id => @scenario.id, :scenario => {:end_year => 2050}}
      expect(response).to be_success
      expect(@scenario.reload.end_year).to eq(2040)
    end

    it "shouldn't update start_year" do
      expect {
        put :update, params: {:id => @scenario.id, :scenario => {:start_year => 2009}}
      }.to_not change { @scenario.reload.start_year }

      expect(response).to be_success
    end

    it "shouldn't update area" do
      put :update, params: {:id => @scenario.id, :scenario => {:area_code => 'de'}}
      expect(response).to be_success
      expect(@scenario.reload.area_code).to eq('nl')
    end

  end
end
