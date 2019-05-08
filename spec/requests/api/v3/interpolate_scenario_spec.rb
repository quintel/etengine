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
      post '/api/v3/scenarios/interpolate',
        params: { scenario: { scenario_id: source.id, end_year: 2040 } }
    end

    before { source }

    it 'saves the scenario' do
      expect { send_data }.to change(Scenario, :count).by(1)
    end

    it 'returns 200 OK' do
      send_data
      expect(response.status).to be(200)
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
      post '/api/v3/scenarios/interpolate',
        params: { scenario: { scenario_id: 999_999, end_year: 2040 }}
    end

    it 'returns 404 Not Found' do
      expect { send_data }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with no scenario ID' do
    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario: { end_year: 2040 } }
    end

    it 'returns 404 Not Found' do
      expect { send_data }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with no end year' do
    before { source }

    let(:send_data) do
      post '/api/v3/scenarios/interpolate',
        params: { scenario: { scenario_id: source.id } }
    end

    it 'raises an error' do
      expect { send_data }.to raise_error(/must have an end year/)
    end
  end
end
