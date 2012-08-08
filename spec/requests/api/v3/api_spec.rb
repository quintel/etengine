require "spec_helper"

# Uses the etsource defined in spec/fixtures/etsource
#
describe "API v3scenario life cycle" do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  it "should create, update, persist" do
    post 'api/v3/scenarios', :scenario => {:area_code => 'nl', :end_year => 2040}

    scenario = JSON.parse(response.body)
    id = scenario['id']
    url = "api/v3/scenarios/#{id}"

    scenario['id'].should_not be_blank
    scenario['area_code'].should == 'nl'
    scenario['end_year'].should == 2040

    # ----- no updates --------------------------------------------------------

    put url, :gqueries => ['bar_demand']

    result = JSON.parse(response.body)['gqueries']
    result['bar_demand']['present'].should == 60.0
    result['bar_demand']['future'].should == 60.0

    # ----- update ------------------------------------------------------------

    put url,
        :scenario => {:user_values => {'foo_demand' => '120'} },
        :gqueries => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['gqueries']
    result['foo_demand']['future'].should == 120.0
    result['bar_demand']['future'].should == 120.0*0.6

    # ----- reset ------------------------------------------------------------

    put url,
        :scenario => {:user_values => {'foo_demand' => 'reset'} },
        :gqueries => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['gqueries']
    result['bar_demand']['future'].should == 60.0
    result['bar_demand']['future'].should == 60.0

    # ----- updating another --------------------------------------------------

    put url,
        :scenario => {:user_values => {'2' => '20', 'foo_demand' => '120'}},
        :gqueries => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['gqueries']
    result['foo_demand']['future'].should == 120.0
    result['bar_demand']['future'].should == 120.0*0.6 + 20

    # ----- updating 3 again --------------------------------------------------

    put url, :scenario => {:user_values => {'foo_demand' => '180'}},
        :gqueries => %w[foo_demand bar_demand]

    result = JSON.parse(response.body)['gqueries']
    result['foo_demand']['present'].should == 100.0
    result['foo_demand']['future'].should == 180.0
    result['bar_demand']['future'].should == 180.0*0.6 + 20

    # ---- using a bad input -----

    put url, :scenario => {:user_values => {'paris_hilton' => '123'}}

    result = JSON.parse(response.body)
    result["errors"][0].should =~ /Missing input/

  # ---- using a bad gquery -----

    put url, :gqueries => ['terminator']

    result = JSON.parse(response.body)
    result["gqueries"]["terminator"]["errors"].should_not be_empty
    result["errors"][0].should =~ /Missing input/

  end

  it "should default to end_year 2050 and area_code 'nl' when creating a scenario" do
    post 'api/v3/scenarios'#, :scenario => {:area_code => 'nl', :end_year => 2040}

    scenario = JSON.parse(response.body)
    scenario['area_code'].should == 'nl'
    scenario['end_year'].should == 2040
  end

end