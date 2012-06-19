require 'spec_helper'

describe Api::ApiScenariosController do

  before(:each) do
    # Current.instance.stub_chain(:gql, :query_multiple).and_return({'foo' => Gql::ResultSet.create([[2010,1],[2010,2]]) })
  end

  describe "index" do
    it "should render" do
      get 'index'
    end
  end

  describe "new" do
    it "should create a new Scenario" do
      expect {
        get 'new'
      }.to change(Scenario, :count).by(1)
      response.should be_redirect
    end

    it "should create and assign params[:settings]" do
      expect {
        get :new, {:settings => {:country => 'uk'}}
      }.to change(Scenario, :count).by(1)

      response.should be_redirect
    end
  end

  pending "show" do
    before(:all) do
      @api_scenario = Scenario.create(Scenario.default_attributes.merge(:title => 'foo'))
    end

    before(:each) do
      # Current.instance.stub_chain(:gql, :query_multiple).and_return({
      #   'foo' => Gql::ResultSet.create([[2010,1],[2010,2]]),
      #   'bar' => Gql::ResultSet.create([[2010,1],[2010,2]])
      # })
    end

    it "should assign @api_scenario" do
      get :show, :id => @api_scenario.id.to_s
      assigns(:api_scenario).should == @api_scenario
    end

    it "should get results" do
      get :show, :id => @api_scenario.id.to_s, :result => ['foo', 'bar']
      assigns(:api_response)[:result].values.should have(2).items
    end

    context "use_fce" do
      it "should be false when created" do
        @api_scenario.use_fce.should be_false
      end

      it "should updated in the scenario when params[:use_fce] is different then the scenario value" do
        get :show, :id => @api_scenario.id.to_s, :use_fce => false
        Scenario.find(@api_scenario.id).use_fce.should be_false

        get :show, :id => @api_scenario.id.to_s, :use_fce => true
        Scenario.find(@api_scenario.id).use_fce.should be_true
      end
    end
  end

  describe 'input_data' do
    before do
      @api_scenario = Scenario.create(Scenario.default_attributes.merge(:title => 'foo'))
    end

    it "should return a valid response" do
      get :input_data, :id => @api_scenario.id
      response.should be_success
    end
  end
end
