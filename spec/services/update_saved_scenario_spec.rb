# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe UpdateSavedScenario do
  let!(:user)     { create(:user) }
  let!(:scenario) { create(:scenario, user: user) }

  let(:token) do
    {
      iss: Settings.identity.api_url,
      aud: 'all_clients',
      sub: 1,
      exp: 3030367768, # Static expiration
      scopes: %w[read write]
    }.with_indifferent_access
  end

  let(:scenario_id) { scenario.id }
  let(:params)      { { scenario_id:, title: 'My scenario' } }
  let(:ability)     { Api::TokenAbility.new(token, user) }

  let(:client) do
    Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        request_params = params
          .except(:id)
          .merge(area_code: scenario.area_code, end_year: scenario.end_year, version: Settings.version_tag)

        stub.put('/api/v1/saved_scenarios/123', request_params) do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id'          => 123,
              'scenario_id' => params[:scenario_id],
              'title'       => params[:title],
              'description' => params[:description],
              'area_code'   => scenario.area_code,
              'end_year'    => scenario.end_year,
              'created_at'  => '2022-12-21T19:45:09Z',
              'updated_at'  => '2022-12-22T12:34:50Z',
              'user'        => { 'id' => user.id, 'name' => user.name }
            }
          ]
        end
      end
    end
  end

  let(:result) do
    described_class.new.call(id: 123, params:, ability:, client:)
  end

  context 'when given valid params' do
    it 'returns a Success' do
      expect(result).to be_success
    end

    it 'returns the saved scenario data as the first return' do
      expect(result.value![0]).to eq({
        'id' => 123,
        'scenario_id' => scenario.id,
        'title' => 'My scenario',
        'description' => nil,
        'area_code' => scenario.area_code,
        'end_year' => scenario.end_year,
        'created_at' => '2022-12-21T19:45:09Z',
        'updated_at' => '2022-12-22T12:34:50Z',
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

  context 'when the saved scenario is not accessible' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          request_params = params.merge(area_code: scenario.area_code, end_year: scenario.end_year, version: Settings.version_tag)

          stub.put('/api/v1/saved_scenarios/123', request_params) do
            raise Faraday::ResourceNotFound
          end
        end
      end
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'has an error message' do
      expect(result.failure).to eq(ServiceResponse.not_found)
    end
  end

  context 'when the params title is blank' do
    let(:params) { super().merge(title: '', version: Settings.version_tag) }

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

  context 'when no params are provided' do
    let(:params) { {} }

    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.put('/api/v1/saved_scenarios/123', { version: Settings.version_tag }) do
            [
              200,
              { 'Content-Type' => 'application/json' },
              {
                'id'          => 123,
                'scenario_id' => scenario.id,
                'title'       => 'My scenario',
                'description' => nil,
                'area_code'   => scenario.area_code,
                'end_year'    => scenario.end_year,
                'created_at'  => '2022-12-21T19:45:09Z',
                'updated_at'  => '2022-12-22T12:34:50Z',
                'user'        => { 'id' => user.id, 'name' => user.name }
              }
            ]
          end
        end
      end
    end

    it 'returns a Success' do
      expect(result).to be_success
    end

    it 'returns the saved scenario data as the first return' do
      expect(result.value![0]).to eq({
        'id' => 123,
        'scenario_id' => scenario.id,
        'title' => 'My scenario',
        'description' => nil,
        'area_code' => scenario.area_code,
        'end_year' => scenario.end_year,
        'created_at' => '2022-12-21T19:45:09Z',
        'updated_at' => '2022-12-22T12:34:50Z',
        'user' => { 'id' => user.id, 'name' => user.name }
      })
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
