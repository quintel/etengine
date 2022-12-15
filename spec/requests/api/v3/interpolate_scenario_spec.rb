require 'spec_helper'

describe 'APIv3 Scenarios', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  let(:source) do
    FactoryBot.create(:scenario, end_year: 2050)
  end

  let(:response_data) do
    send_data
    JSON.parse(response.body)
  end

  context 'with valid parameters' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 }
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
        params: { end_year: 2040 }
    end

    it 'returns 404 Not Found' do
      send_data
      expect(response.status).to be(404)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ['Scenario not found'])
    end
  end

  context 'with no end year' do
    before { source }

    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate", params: {}
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
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: access_token_header(user, :write)
    end

    let(:user) { create(:user) }

    before { source.update!(owner: user, private: true) }

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
      expect(response_data['owner']['id']).to eq(user.id)
    end
  end

  context 'with an other-owned public scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: access_token_header(user, :write)
    end

    let(:user) { create(:user) }

    before { source.update!(owner: create(:user)) }

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
      expect(response_data['owner']['id']).to eq(user.id)
    end
  end

  context 'with an other-owned private scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers: access_token_header(user, :write)
    end

    let(:user) { create(:user) }

    before { source.update!(private: true, owner: create(:user)) }

    it 'returns 404 Not Found' do
      send_data
      expect(response).to be_not_found
    end
  end
end
