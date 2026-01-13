# frozen_string_literal: true

require 'spec_helper'

describe 'APIv3 Scenarios interpolate_collection', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  let(:response_data) do
    send_data
    JSON.parse(response.body)
  end

  let(:user) { create(:user) }
  let(:token_header) { access_token_header(user, :write) }

  let(:scenario_2030) do
    create(:scenario, user:, end_year: 2030, user_values: { 'grouped_input_one' => 50.0 })
  end

  let(:scenario_2040) do
    create(:scenario, user:, end_year: 2040, user_values: { 'grouped_input_one' => 75.0 })
  end

  let(:scenario_2050) do
    create(:scenario, user:, end_year: 2050, user_values: { 'grouped_input_one' => 100.0 })
  end

  context 'with valid parameters' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, scenario_2040.id, scenario_2050.id], end_years: [2035, 2045] },
        headers: token_header
    end

    before do
      scenario_2030
      scenario_2040
      scenario_2050
    end

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the interpolated scenarios' do
      expect { send_data }.to change(Scenario, :count).by(2)
    end

    it 'returns an array of two scenarios' do
      expect(response_data.length).to eq(2)
    end

    it 'returns scenario for year 2035' do
      expect(response_data[0]).to include('end_year' => 2035)
    end

    it 'returns scenario for year 2045' do
      expect(response_data[1]).to include('end_year' => 2045)
    end

    it 'sets the area code' do
      expect(response_data[0]).to include('area_code' => scenario_2030.area_code)
    end
  end

  context 'with missing scenario_ids' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { end_years: [2035] },
        headers: token_header
    end

    it 'returns 400 Bad Request' do
      send_data
      expect(response.status).to eq(400)
    end

    it 'returns an error message' do
      expect(response_data).to include('errors' => ['param is missing or the value is empty: scenario_ids'])
    end
  end

  context 'with missing end_years' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, scenario_2050.id] },
        headers: token_header
    end

    before do
      scenario_2030
      scenario_2050
    end

    it 'returns 400 Bad Request' do
      send_data
      expect(response.status).to eq(400)
    end

    it 'returns an error message' do
      expect(response_data).to include('errors' => ['param is missing or the value is empty: end_years'])
    end
  end

  context 'with a single scenario' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2050.id], end_years: [2035] },
        headers: token_header
    end

    before { scenario_2050 }

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the interpolated scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'returns an array with one scenario' do
      expect(response_data.length).to eq(1)
    end

    it 'returns scenario for year 2035' do
      expect(response_data[0]).to include('end_year' => 2035)
    end
  end

  context 'with a non-existent scenario ID' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, 999999], end_years: [2025] },
        headers: token_header
    end

    before { scenario_2030 }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to eq(422)
    end

    it 'returns an error message' do
      expect(response_data['errors']['scenario_ids'].first).to match(/not found/)
    end
  end

  context 'with an inaccessible private scenario' do
    let(:other_user) { create(:user) }

    let(:private_scenario) do
      create(:scenario, user: other_user, end_year: 2050, private: true)
    end

    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, private_scenario.id], end_years: [2040] },
        headers: token_header
    end

    before do
      scenario_2030
      private_scenario
    end

    it 'returns 404 Not Found' do
      send_data
      expect(response.status).to eq(404)
    end
  end

  context 'with scenarios having different area codes' do
    let(:scenario_de) do
      create(:scenario, user:, end_year: 2050, area_code: 'de')
    end

    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, scenario_de.id], end_years: [2040] },
        headers: token_header
    end

    before do
      scenario_2030
      scenario_de
    end

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to eq(422)
    end

    it 'returns an error message' do
      expect(response_data['errors']['scenario_ids'].first).to match(/same area code/)
    end
  end

  context 'with a target year after the latest scenario' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, scenario_2050.id], end_years: [2055] },
        headers: token_header
    end

    before do
      scenario_2030
      scenario_2050
    end

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to eq(422)
    end

    it 'returns an error message' do
      expect(response_data['errors']['end_years'].first).to match(/must be prior to the latest scenario end year/)
    end
  end

  context 'with a target year before the first scenario start year' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, scenario_2050.id], end_years: [2011] },
        headers: token_header
    end

    before do
      scenario_2030
      scenario_2050
    end

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to eq(422)
    end

    it 'returns an error message' do
      expect(response_data['errors']['end_years'].first).to match(/must be posterior to the first scenario start year/)
    end
  end

  context 'with self-owned private scenarios' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario_ids: [scenario_2030.id, scenario_2050.id], end_years: [2040] },
        headers: token_header
    end

    before do
      scenario_2030.update!(private: true)
      scenario_2050.update!(private: true)
    end

    it 'returns 200 OK' do
      send_data
      expect(response.status).to eq(200)
    end

    it 'saves the interpolated scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'sets the new scenario to private' do
      expect(response_data[0]).to include('private' => true)
    end
  end

end
