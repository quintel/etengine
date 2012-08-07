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
    settings["4"]["start_value"].should == 60

    # ----- updating 2 --------------------------------------------------------

    get api_url, :input => {'4' => '500'}
    get settings_url
    settings = JSON.parse(response.body)
    settings["4"]["start_value"].should == 60
    settings["4"]["user_value"].should == 500

    # ----- updating again ----------------------------------------------------

    get api_url, :input => {'4' => '300', '1' => '50'}
    get settings_url
    settings = JSON.parse(response.body)
    settings["4"]["user_value"].should == 300
    settings["1"]["user_value"].should == 50

    # ----- updating going over min/max ----------------------------------------------------
    # api simply accepts without further checking :(
    #
    get api_url, :input => {'1' => '-100'}
    get settings_url
    settings = JSON.parse(response.body)
    settings["1"]["user_value"].should == -100


  end


end