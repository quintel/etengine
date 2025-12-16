require 'spec_helper'

describe 'APIv3 Scenarios', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  let(:response_data) do
    send_data
    JSON.parse(response.body)
  end

  let(:user) { create(:user) }
  let(:token_header) { access_token_header(user, :write) }

  let(:source) do
    FactoryBot.create(:scenario, user: user, end_year: 2050)
  end

  context 'with valid parameters' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: token_header
    end

    before { source }

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'sends the scenario ID' do
      expect(response_data).to include('id' => Scenario.last.id)
    end

    it 'sets the area code' do
      expect(response_data).to include('area_code' => source.area_code)
    end

    it 'sets the end year' do
      expect(response_data).to include('end_year' => 2040)
    end
  end

  context 'with an invalid scenario ID' do
    let(:send_data) do
      post '/api/v3/scenarios/999999/interpolate',
        params: { end_year: 2040 },
        headers: token_header
    end

    it 'returns 404 Not Found' do
      send_data
      expect(response.status).to be(404)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ["No such scenario: 999999"])
    end
  end

  context 'with no end year' do
    before { source }

    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate", params: {}, headers: token_header
    end

    it 'returns 400 Bad Request' do
      send_data
      expect(response.status).to be(400)
    end

    it 'returns the error' do
      expect(response_data).to include('errors' => [
        'Interpolated scenario must have an end year'
      ])
    end
  end

  context 'with a self-owned private scenario' do
    let(:user) { create(:user) }

    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: access_token_header(user, :write)
    end

    before do
      source.delete_all_users
      source.user = user
      source.reload.update!(private: true)
    end

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'sets the new scenario to private' do
      expect(response_data).to include('private' => true)
    end

    it 'sets the scenario owner' do
      scenario = Scenario.last
      expect(scenario.users).to include(user)
      expect(scenario.scenario_users.find_by(user: user).role_id).to eq(3)
    end
  end

  context 'with an other-owned public scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: access_token_header(user, :write)
    end

    let(:user) { create(:user) }

    before do
      source.delete_all_users
      source.user = user
    end

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'sets the new scenario to public' do
      expect(response_data).to include('private' => false)
    end

    it 'sets the scenario owner' do
      scenario = Scenario.last
      expect(scenario.users).to include(user)
      expect(scenario.scenario_users.find_by(user: user).role_id).to eq(3)
    end
  end

  context 'with an other-owned private scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: access_token_header(user, :write)
    end

    let(:user) { create(:user) }

    before do
      source.delete_all_users
      source.user = create(:user)
      source.reload.update(private: true)
    end

    it 'returns 404 Not Found' do
      send_data
      expect(response).to be_not_found
    end
  end

  context 'with a valid start scenario id' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: access_token_header(user, :write)
    end

    let(:start_scenario) { create(:scenario, end_year: 2030, user: user) }

    before do
      source
      start_scenario
    end

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'sends the scenario ID' do
      expect(response_data).to include('id' => Scenario.last.id)
    end

    it 'sets the area code' do
      expect(response_data).to include('area_code' => source.area_code)
    end

    it 'sets the end year' do
      expect(response_data).to include('end_year' => 2040)
    end
  end

  context 'with an inexistent start scenario id' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: 999999 },
        headers: token_header
    end

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ["Start scenario not found"])
    end
  end

  context 'with an inaccessible start scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2030, user: other_user, private: true) }
    let(:other_user) { create(:user) }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ["Start scenario not accessible"])
    end
  end

  context 'with same start scenario as source scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: source.id },
        headers: token_header
    end

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data).to include(
        'errors' => ['Start scenario must not be the same as the original scenario'])
    end
  end

  context 'with an invalid interpolation year (earlier than start scenario)' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2055, user: user) }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ['Start scenario must have an end ' \
        "year equal or prior to the original scenario (#{source.start_year})"])
    end
  end

  context 'with an invalid interpolation year (earlier than start scenario)' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2045, user: user) }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ['Interpolated scenario must have an ' \
        "end year equal or posterior to the start scenario (#{start_scenario.end_year})"])
    end
  end

  context 'with an invalid start scenario area code' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2030, user: user, area_code: 'de') }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ['Start scenario must have the same ' \
        "area code as the original scenario (#{source.area_code})"])
    end
  end

end
