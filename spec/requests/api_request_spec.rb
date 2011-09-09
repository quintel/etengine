require "spec_helper"

describe "api_scenario life cycle" do
  before do 
    @input1 = Input.create(:query => "UPDATE(V(lft), demand, USER_INPUT())")
    @input2 = Input.create(:query => "UPDATE(V(mid), demand, USER_INPUT())")
    @gquery1 = Gquery.create(:key => 'lft_demand', :query => 'V(lft; demand)')
    @gquery2 = Gquery.create(:key => 'rgt_demand', :query => 'V(rgt; demand)')
    refresh_gql
  end

  def refresh_gql
    sleep(1)

    Current.gql = Qernel::GraphParser.gql_stubbed("
      lft(100) == s(1.0) ==> rgt()
      mid( 50) == s(1.0) ==> rgt()
    ")
  end

  it "should create, update, persist" do
    post 'api/v2/api_scenarios.json'
    scenario = JSON.parse(response.body)['api_scenario']
    id = scenario['id']
    url = "api/v2/api_scenarios/#{id}.json"

    scenario['id'].should_not be_blank
    scenario['country'].should == 'nl'
    scenario['end_year'].should == 2040
    scenario['region'].should == nil
    scenario['use_fce'].should == false
    scenario['user_values'].should be_empty

    refresh_gql

    # ----- no updates --------------------------------------------------------

    get url, :r => 'rgt_demand'

    result = JSON.parse(response.body)['result']
    result['rgt_demand'][0][1].should == 150.0
    result['rgt_demand'][1][1].should == 150.0

    # ----- update ------------------------------------------------------------

    refresh_gql

    get url, :input => {@input1.id.to_s => '120'}, :result => %w[lft_demand rgt_demand]

    result = JSON.parse(response.body)['result']
    result['lft_demand'][1][1].should == 120.0
    result['rgt_demand'][1][1].should == 170.0

    # ----- updating another --------------------------------------------------

    refresh_gql

    get url, :input => {@input2.id.to_s => '80'}, :result => %w[lft_demand rgt_demand]

    result = JSON.parse(response.body)['result']
    result['lft_demand'][1][1].should == 120.0
    result['rgt_demand'][1][1].should == 200.0

    # ----- updating 1 again --------------------------------------------------

    refresh_gql

    get url, :input => {@input1.id.to_s => '180'}, :r => 'lft_demand'

    result = JSON.parse(response.body)['result']
    result['lft_demand'][0][1].should == 100.0
    result['lft_demand'][1][1].should == 180.0


  end

end