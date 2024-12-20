# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe UpsertTransitionPath do
  let!(:user)      { create(:user) }
  let!(:scenario1) { create(:scenario, end_year: 2040, user: user) }
  let!(:scenario2) { create(:scenario, end_year: 2050, user: user) }

  let(:token) do
    {
      iss: Settings.identity.api_url,
      aud: 'all_clients',
      sub: 1,
      exp: 2730367768, # Static expiration
      scopes: %w[read write]
    }.with_indifferent_access
  end

  let(:params)  { { scenario_ids: [scenario1.id, scenario2.id], title: 'My transition path' } }
  let(:ability) { Api::TokenAbility.new(token, user) }

  let(:client) do
    Faraday.new do |builder|
      builder.adapter(:test) do |stub|
        request_params = params.slice(
          :scenario_ids,
          :title
        ).merge(
          area_code: scenario2.area_code,
          end_year:  scenario2.end_year
        )

        stub.put('/api/v1/transition_paths/123', request_params) do
          [
            200,
            { 'Content-Type' => 'application/json' },
            {
              'id'           => 123,
              'scenario_ids' => params[:scenario_ids],
              'title'        => params[:title],
              'area_code'    => scenario2.area_code,
              'end_year'     => scenario2.end_year,
              'created_at'   => '2022-12-21T19:45:09Z',
              'updated_at'   => '2022-12-22T12:34:50Z',
              'user'         => { 'id' => user.id, 'name' => user.name }
            }
          ]
        end
      end
    end
  end

  let(:result) do
    described_class.new(
      endpoint_path: '/api/v1/transition_paths/123',
      method: :put
    ).call(params:, ability:, client:)
  end

  context 'when given valid params' do
    it 'returns a Success' do
      expect(result).to be_success
    end

    it 'returns the transition path data' do
      expect(result.value!).to eq({
        'id' => 123,
        'scenario_ids' => [scenario1.id, scenario2.id],
        'title' => 'My transition path',
        'area_code' => scenario2.area_code,
        'end_year' => scenario2.end_year,
        'created_at' => '2022-12-21T19:45:09Z',
        'updated_at' => '2022-12-22T12:34:50Z',
        'user' => { 'id' => user.id, 'name' => user.name }
      })
    end
  end

  context 'when given additional paramters' do
    # Faraday will throw an error if it receives a parameter or value that it doesn't expect.
    let(:params) do
      {
        scenario_ids: [scenario1.id, scenario2.id],
        title: 'My transition path',
        end_year: -2050,
        extra: 'parameter'
      }
    end

    it 'returns a Success' do
      expect(result).to be_success
    end
  end

  context 'when a scenario is not accessible' do
    before do
      scenario1.delete_all_users
      scenario1.reload.update(user: create(:user))
      scenario1.reload.update(private: true)
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'returns an error message' do
      expect(result.failure).to eq(scenario_ids: { scenario1.id => ['does not exist'] })
    end
  end

  context 'when the upstream API returns 422 Unprocessable Entity' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.put('/api/v1/transition_paths/123') do
            raise stub_faraday_422('title' => 'is invalid')
          end
        end
      end
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'returns the error message' do
      expect(result.failure).to eq('title' => 'is invalid')
    end
  end

  context 'when the upstream API returns 404 Not found' do
    let(:client) do
      Faraday.new do |builder|
        builder.adapter(:test) do |stub|
          stub.put('/api/v1/transition_paths/123') do
            raise Faraday::ResourceNotFound
          end
        end
      end
    end

    it 'returns a Failure' do
      expect(result).to be_failure
    end

    it 'returns a 404 response' do
      expect(result.failure).to eq(ServiceResponse.not_found)
    end
  end
end
