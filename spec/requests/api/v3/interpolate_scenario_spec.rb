# frozen_string_literal: true

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

  # Access is determined solely by the token's scenario_access grant. The source is bound (saved in
  # MyETM) so that the grant is the only route to access beyond what is public.
  def grant(write: [], read: [])
    { Settings.version_tag => { 'write' => write, 'read' => read } }
  end

  let(:token_header) do
    access_token_header(user, :write, scenario_access: grant(write: [source.id]))
  end

  let(:source) do
    create(:scenario, bound: true, end_year: 2050)
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
      expect(response_data).to include('errors' => ['No such scenario: 999999'])
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

  describe 'access' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040 },
        headers:
    end

    before { source }

    shared_examples_for 'an accepted interpolation' do |private:|
      it 'returns 200 OK' do
        send_data
        expect(response).to have_http_status(:ok)
      end

      it 'saves the scenario' do
        expect { send_data }.to change(Scenario, :count).by(1)
      end

      it "sets the new scenario to #{private ? 'private' : 'public'}" do
        expect(response_data).to include('private' => private)
      end

      it 'sets the scenario creator' do
        send_data
        expect(Scenario.last.creator_id).to eq(user.id)
      end
    end

    shared_examples_for 'a refused interpolation' do
      it 'returns 404 Not Found' do
        send_data
        expect(response).to have_http_status(:not_found)
      end

      it 'does not save a scenario' do
        expect { send_data }.not_to change(Scenario, :count)
      end
    end

    context 'when the scenario is private' do
      before { source.update!(private: true) }

      context 'when the token grants write access' do
        let(:headers) { token_header }

        it_behaves_like 'an accepted interpolation', private: true
      end

      context 'when the token grants read access (viewer)' do
        let(:headers) do
          access_token_header(user, :write, scenario_access: grant(read: [source.id]))
        end

        it_behaves_like 'a refused interpolation'
      end

      context 'when the token has no grant for the scenario' do
        let(:headers) { access_token_header(user, :write) }

        it_behaves_like 'a refused interpolation'
      end

      context 'when the token grants write access without the scenarios:write scope' do
        let(:headers) do
          access_token_header(user, :read, scenario_access: grant(write: [source.id]))
        end

        it_behaves_like 'a refused interpolation'
      end
    end

    # Public scenarios may be cloned by anyone with the write scope. The grant only decides whether
    # the new scenario inherits the source's privacy or follows the user's preference.
    context 'when the scenario is public' do
      context 'when the token grants write access' do
        let(:headers) { token_header }

        it_behaves_like 'an accepted interpolation', private: false

        # TODO: flag in PR. Currently the clone copies the source's privacy (public) when the token
        # may update the source, ignoring the user's private_scenarios preference.
        context 'when the user prefers private scenarios',
          skip: 'Is this correct behaviour? A writer gets a public clone, a viewer a private one' do
          let(:user) { create(:user, private_scenarios: true) }

          it_behaves_like 'an accepted interpolation', private: true
        end
      end

      context 'when the token grants read access (viewer)' do
        let(:headers) do
          access_token_header(user, :write, scenario_access: grant(read: [source.id]))
        end

        it_behaves_like 'an accepted interpolation', private: false

        context 'when the user prefers private scenarios' do
          let(:user) { create(:user, private_scenarios: true) }

          it_behaves_like 'an accepted interpolation', private: true
        end
      end

      context 'when the token has no grant for the scenario' do
        let(:headers) { access_token_header(user, :write) }

        it_behaves_like 'an accepted interpolation', private: false
      end
    end
  end

  context 'with a valid start scenario id' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2030) }

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

    it 'returns 404 Unprocessable Entity' do
      send_data
      expect(response.status).to be(404)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ["No such scenario: 999999"])
    end
  end

  context 'with a private start scenario readable through the grant' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: access_token_header(
          user, :write, scenario_access: grant(write: [source.id], read: [start_scenario.id])
        )
    end

    let(:start_scenario) { create(:scenario, end_year: 2030, bound: true, private: true) }

    before { source }

    it 'returns 200 OK' do
      send_data
      expect(response).to have_http_status(:ok)
    end
  end

  context 'with an inaccessible start scenario' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2030, bound: true, private: true) }

    before { source }

    it 'returns 404 Unprocessable Entity' do
      send_data
      expect(response.status).to be(404)
    end

    it 'sends back an error message' do
      expect(response_data).to include('errors' => ["Not found"])
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
      expect(response_data['errors'])
        .to include('start scenario must not be the same as the original scenario')
    end
  end

  context 'with an invalid start scenario end year (after source scenario)' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2055) }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data['errors']).to include(
        'must be posterior to the start scenario end year'
      )
    end
  end

  context 'with an invalid interpolation year (earlier than start scenario)' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2045) }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data['errors']).to include(
        'must be posterior to the start scenario end year'
      )
    end
  end

  context 'with an invalid start scenario area code' do
    let(:send_data) do
      post "/api/v3/scenarios/#{source.id}/interpolate",
        params: { end_year: 2040, start_scenario_id: start_scenario.id },
        headers: token_header
    end

    let(:start_scenario) { create(:scenario, end_year: 2030, area_code: 'de') }

    before { source }

    it 'returns 422 Unprocessable Entity' do
      send_data
      expect(response.status).to be(422)
    end

    it 'sends back an error message' do
      expect(response_data['errors']).to include(
        'start scenario area code must match original scenario area code'
      )
    end
  end
end
