# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe CreateSavedScenario do
  let!(:user)     { create(:user) }
  let!(:scenario) { create(:scenario, user: user) }

  let(:token) do
    {
      iss: Settings.identity.api_url,
      aud: 'all_clients',
      sub: 1,
      exp: 2730367768, # Static expiration
      scopes: %w[read write]
    }.with_indifferent_access
  end

  let(:scenario_id) { scenario.id }
  let(:params)      { { scenario_id:, title: 'My scenario' } }
  let(:ability)     { Api::TokenAbility.new(token, user) }

  let(:client) do
    Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        request_params = params.merge(area_code: scenario.area_code, end_year: scenario.end_year)

        stub.post('/api/v1/saved_scenarios', request_params) do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id'          => 1,
              'scenario_id' => params[:scenario_id],
              'title'       => params[:title],
              'description' => params[:description],
              'area_code'   => scenario.area_code,
              'end_year'    => scenario.end_year,
              'created_at'  => '2022-12-21T19:45:09Z',
              'updated_at'  => '2022-12-21T19:45:09Z',
              'user'        => { 'id' => user.id, 'name' => user.name }
            }
          ]
        end
      end
    end
  end

  let(:result) do
    described_class.new.call(params:, ability:, client:)
  end

  context 'when given valid params' do
    it 'returns a Success' do
      expect(result).to be_success
    end

    it 'returns the saved scenario data as the first return' do
      expect(result.value![0]).to eq({
        'id' => 1,
        'scenario_id' => scenario.id,
        'title' => 'My scenario',
        'description' => nil,
        'area_code' => scenario.area_code,
        'end_year' => scenario.end_year,
        'created_at' => '2022-12-21T19:45:09Z',
        'updated_at' => '2022-12-21T19:45:09Z',
        'user' => { 'id' => user.id, 'name' => user.name }
      })
    end

    it 'returns the scenario as the second return' do
      expect(result.value![1]).to eq(scenario)
    end
  end

  context 'when the scenario does not exist' do
    before do
      scenario.destroy!
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'has an error message' do
      expect(result.failure).to eq({ scenario_id: ['does not exist'] })
    end
  end

  context 'when the scenario is not accessible' do
    before do
      scenario.delete_all_users
      scenario.reload.update(user: create(:user))
      scenario.reload.update(private: true)
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'has an error message' do
      expect(result.failure).to eq({ scenario_id: ['does not exist'] })
    end
  end

  context 'when the params title is nil' do
    let(:params) { super().merge(title: nil) }

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'has an error message' do
      expect(result.failure.to_hash).to eq({ title: ['must be a string'] })
    end
  end

  context 'when the params title is blank' do
    let(:params) { super().merge(title: '') }

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'has an error message' do
      expect(result.failure.to_hash).to eq({ title: ['must be filled'] })
    end
  end

  context 'when the params scenario_id is nil' do
    let(:params) { super().merge(scenario_id: nil) }

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'has an error message' do
      expect(result.failure.to_hash).to eq({ scenario_id: ['must be an integer'] })
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
