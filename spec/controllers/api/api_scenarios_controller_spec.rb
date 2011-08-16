require 'spec_helper'

describe Api::ApiScenariosController do

  before(:each) do
    stub_etm_layout_methods!
    Current.stub_chain(:gql, :query).and_return Gql::ResultSet.create([[2010,1],[2010,2]])
  end

  describe "index" do
    it "should render" do
      get 'index'
    end
  end

  describe "new" do
    it "should create a new ApiScenario" do
      expect {
        get 'new'
      }.to change(ApiScenario, :count).by(1)
      response.should be_redirect
    end

    it "should create and assign params[:settings]" do
      api_session_key = Time.now.to_i

      expect {
        get :new, {:settings => {:country => 'uk', :api_session_key => api_session_key.to_s}}
      }.to change(ApiScenario, :count).by(1)

      ApiScenario.find_by_api_session_key(api_session_key).should_not be_nil
      response.should be_redirect
    end
  end

  describe "show" do
    before(:all) do
      @api_scenario = ApiScenario.create(Scenario.default_attributes.merge(:title => 'foo'))
    end

    it "should assign @api_scenario" do
      get :show, :id => @api_scenario.api_session_key.to_s
      assigns(:api_scenario).api_session_key.to_s.should == @api_scenario.api_session_key.to_s
    end

    it "should get results" do
      Current.instance.stub_chain(:gql, :query).and_return(0.0)
      get :show, :id => @api_scenario.api_session_key, :result => ['gquery_key', 'gquery_key2']
      assigns(:results).values.should have(2).items
    end

    context "use_fce" do
      it "should be false when created" do
        @api_scenario.use_fce.should be_false
      end
      
      it "should updated in the scenario when params[:use_fce] is different then the scenario value" do
        get :show, :id => @api_scenario.api_session_key, :use_fce => false
        ApiScenario.find_by_api_session_key(@api_scenario.api_session_key).use_fce.should be_false

        get :show, :id => @api_scenario.api_session_key, :use_fce => true
        ApiScenario.find_by_api_session_key(@api_scenario.api_session_key).use_fce.should be_true
      end
    end
  end
end
