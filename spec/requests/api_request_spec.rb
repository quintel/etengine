require "spec_helper"

# Uses the etsource defined in spec/fixtures/etsource
#
describe "api_scenario life cycle" do
  before(:all) do 
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  it "should return user_values" do
    post 'api/v2/api_scenarios.json'

    scenario     = JSON.parse(response.body)['scenario']
    settings_url = "api/v2/api_scenarios/#{scenario['id']}/user_values.json"
    api_url      = "api/v2/api_scenarios/#{scenario['id']}.json"

    # ----- no updates --------------------------------------------------------

    get settings_url
    settings = JSON.parse(response.body)
    settings["1"]["max_value"].should == 100
    settings["1"]["min_value"].should == 0
    settings["1"]["start_value"].should == 50
    settings["2"]["start_value"].should == 100*100 # start_value_gql*factor
    
    # ----- updating 2 --------------------------------------------------------
    
    get api_url, :input => {'2' => '500'}
    get settings_url
    settings = JSON.parse(response.body)
    settings["2"]["start_value"].should == 100*100
    settings["2"]["user_value"].should == 500

    # ----- updating again ----------------------------------------------------
    
    get api_url, :input => {'2' => '300', '1' => '50'}
    get settings_url
    settings = JSON.parse(response.body)
    settings["2"]["user_value"].should == 300
    settings["1"]["user_value"].should == 50
    
    # ----- updating going over min/max ----------------------------------------------------
    # api simply accepts without further checking :(
    #
    get api_url, :input => {'1' => '-100'}
    get settings_url
    settings = JSON.parse(response.body)
    settings["1"]["user_value"].should == -100


  end

  it "should create, update, persist" do
    post 'api/v2/api_scenarios.json'
    
    scenario = JSON.parse(response.body)['scenario']
    id = scenario['id']
    url = "api/v2/api_scenarios/#{id}.json"

    scenario['id'].should_not be_blank
    scenario['area_code'].should == 'nl'
    scenario['end_year'].should == 2040
    scenario['use_fce'].should == false
    scenario['user_values'].should be_empty

    # ----- no updates --------------------------------------------------------

    get url, :r => 'bar_demand'

    result = JSON.parse(response.body)['result']
    result['bar_demand'][0][1].should == 60.0
    result['bar_demand'][1][1].should == 60.0

    # ----- update ------------------------------------------------------------

    get url, :input => {'3' => '120'}, :result => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['result']
    result['foo_demand'][1][1].should == 120.0
    result['bar_demand'][1][1].should == 120.0*0.6

    # ----- updating another --------------------------------------------------

    get url, :input => {'2' => '20'}, :result => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['result']
    result['foo_demand'][1][1].should == 120.0
    result['bar_demand'][1][1].should == 120.0*0.6 + 20

    # ----- updating 3 again --------------------------------------------------

    get url, :input => {'3' => '180'}, :result => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['result']
    result['foo_demand'][0][1].should == 100.0
    result['foo_demand'][1][1].should == 180.0
    result['bar_demand'][1][1].should == 180.0*0.6 + 20
  end


  it "should reset" do
    post 'api/v2/api_scenarios.json'
    
    scenario = JSON.parse(response.body)['scenario']
    id       = scenario['id']
    url      = "api/v2/api_scenarios/#{id}.json"

    # ----- update ------------------------------------------------------------

    get url, :input => {'3' => '120'}, :result => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['result']
    result['foo_demand'][1][1].should == 120.0
    result['bar_demand'][1][1].should == 120.0*0.6

    # ----- reset --------------------------------------------------

    get url, :reset => true, :result => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['result']
    result['foo_demand'][1][1].should == 100.0
  end


  it "should load from scenario" do
    post 'api/v2/api_scenarios.json', settings: {scenario_id: 2999}
    
    scenario = JSON.parse(response.body)['scenario']
    id       = scenario['id']
    url      = "api/v2/api_scenarios/#{id}.json"

    # ----- no updates ------------------------------------------------------------

    get url, :result => %w[foo_demand bar_demand]
    result = JSON.parse(response.body)['result']
    result['foo_demand'][1][1].should == 250

    # ----- reset --------------------------------------------------

    get url, :reset => true, :result => %w[foo_demand bar_demand]
    result = JSON.parse(response.body)['result']
    result['foo_demand'][1][1].should == 100.0
  end





end