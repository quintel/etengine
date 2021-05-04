require "spec_helper"

# Uses the etsource defined in spec/fixtures/etsource
#
describe "API v3scenario life cycle", :etsource_fixture do
  it "should create, update, persist" do
    post '/api/v3/scenarios', params: {:scenario => {:area_code => 'nl', :end_year => 2040}}

    scenario = JSON.parse(response.body)
    id = scenario['id']
    url = "/api/v3/scenarios/#{id}"

    expect(scenario['id']).not_to be_blank
    expect(scenario['area_code']).to eq('nl')
    expect(scenario['end_year']).to eq(2040)

    # ----- no updates --------------------------------------------------------

    put url, params: { :gqueries => ['bar_demand'] }

    result = JSON.parse(response.body)['gqueries']
    expect(result['bar_demand']['present']).to eq(60.0)
    expect(result['bar_demand']['future']).to eq(60.0)

    # ----- update ------------------------------------------------------------

    put url,
        params: {
          :scenario => {:user_values => {'foo_demand' => '90'} },
          :gqueries => %w[foo_demand bar_demand]
        }

    result = JSON.parse(response.body)['gqueries']
    expect(result['foo_demand']['future']).to eq(90.0)
    expect(result['bar_demand']['future']).to eq(90.0*0.6)

    # ----- reset ------------------------------------------------------------

    put url,
        params: {
          :scenario => {:user_values => {'foo_demand' => 'reset'} },
          :gqueries => %w[foo_demand bar_demand]
        }

    result = JSON.parse(response.body)['gqueries']
    expect(result['bar_demand']['future']).to eq(60.0)
    expect(result['bar_demand']['future']).to eq(60.0)

    # ----- updating another --------------------------------------------------

    put url,
        params: {
                                                 :scenario => {:user_values => {'input_2' => '20',
                                                                            'foo_demand' => '80'}},
                                             :gqueries => %w[foo_demand bar_demand]
    }

    result = JSON.parse(response.body)['gqueries']
    expect(result['foo_demand']['future']).to eq(80.0)
    expect(result['bar_demand']['future']).to eq(80.0*0.6 + 20)

    # ----- updating 3 again --------------------------------------------------

    put url, params: {
          :scenario => {:user_values => {'foo_demand' => '25'}},
          :gqueries => %w[foo_demand bar_demand]
        }

    result = JSON.parse(response.body)['gqueries']
    expect(result['foo_demand']['present']).to eq(100.0)
    expect(result['foo_demand']['future']).to eq(25.0)
    expect(result['bar_demand']['future']).to eq(25.0*0.6 + 20)

    # ---- using a bad input -----

    put url, params: {:scenario => {:user_values => {'paris_hilton' => '123'}}}

    result = JSON.parse(response.body)
    expect(result["errors"][0]).to match(/does not exist/)

    # ---- using a bad gquery -----

    put url, params: { :gqueries => ['terminator'] }

    result = JSON.parse(response.body)
    expect(result["errors"]).not_to be_empty
    expect(result["errors"][0]).to match(/does not exist/)
  end

  it "should default to end_year 2040 and area_code 'nl' when creating a scenario" do
    post '/api/v3/scenarios', params: {:scenario => {}}

    scenario = JSON.parse(response.body)
    expect(scenario['area_code']).to eq('nl')
    expect(scenario['end_year']).to eq(2050)
  end


end
