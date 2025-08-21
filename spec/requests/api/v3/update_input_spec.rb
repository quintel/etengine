# frozen_string_literal: true

require 'spec_helper'

describe 'Updating inputs with API v3' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:user) { create(:user) }
  let(:token_header) { access_token_header(user, :write) }

  let(:scenario) do
    FactoryBot.create(:scenario,
      user:,
      user_values: { 'unrelated_one' => 25.0 },
      balanced_values: { 'unrelated_two' => 75.0 })
  end

  before do
    allow(Input).to receive(:records).and_return(
      'balanced_one' =>
        FactoryBot.build(
          :input,
          start_value: 100.0,
          key: 'balanced_one',
          share_group: 'grouped',
          priority: 0
        ),
      'balanced_two' =>
        FactoryBot.build(
          :input,
          start_value: 0.0,
          key: 'balanced_two',
          share_group: 'grouped',
          priority: 0
        ),
      'unrelated_one' =>
        FactoryBot.build(
          :input,
          key: 'unrelated_one',
          share_group: 'diode',
          priority: 0
        ),
      'unrelated_two' =>
        FactoryBot.build(
          :input,
          key: 'unrelated_two',
          share_group: 'diode',
          priority: 0
        ),
      'nongrouped' =>
        FactoryBot.build(
          :input,
          key: 'nongrouped',
          priority: 0
        ),
      'boolean_one' =>
        FactoryBot.build(
          :input,
          key: 'boolean_one',
          start_value: 0.0,
          min_value: 0.0,
          max_value: 1.0,
          step_value: 1.0,
          unit: 'bool',
          share_group: '',
          priority: 0
        )
    )

    allow(Input).to receive(:all).and_return(Input.records.values)
  end

  def put_scenario(values: {}, params: {}, headers: token_header)
    values = values.map { |k, v| [k.to_s, v.to_s] }.to_h

    put("/api/v3/scenarios/#{scenario.id}",
      params: params.merge(scenario: { user_values: values }),
      headers:)

    scenario.reload
  end

  def nonbalanced_scenario(values: {}, params: {}, headers: token_header)
    put_scenario(values:, params: params.merge(autobalance: false), headers: token_header)
  end

  def autobalance_scenario(values: {}, params: {}, headers: {})
    put_scenario(values:, params: params.merge(autobalance: true), headers: token_header)
  end

  # --------------------------------------------------------------------------

  shared_examples_for 'updating inputs' do
    it 'preserves unrelated user values' do
      expect(scenario.user_values).to include('unrelated_one' => 25.0)
    end

    it 'preserves unrelated balanced values' do
      expect(scenario.balanced_values).to include('unrelated_two' => 75.0)
    end
  end

  # --------------------------------------------------------------------------

  context 'when autobalance=false,' do
    context 'when providing a non-grouped single value' do
      before do
        nonbalanced_scenario(values: { nongrouped: 50 })
      end

      it 'responds 200 OK' do
        decoded_token = ETEngine::TokenDecoder.decode(token_header['Authorization'].split(' ').last)
        expect(response.status).to be(200)
      end

      it 'sets the user value' do
        expect(scenario.user_values).to include('nongrouped' => 50.0)
      end

      it 'includes the scenario data' do
        json = JSON.parse(response.body)

        expect(json).to have_key('scenario')

        expect(json['scenario']).to include('id'        => scenario.id)
        expect(json['scenario']).to include('area_code' => 'nl')
        expect(json['scenario']).to include('end_year'  => scenario.end_year)
        expect(json['scenario']).to include('template'  => nil)
        expect(json['scenario']).to include('source'    => nil)

        expect(json['scenario']).to have_key('created_at')

        expect(json['scenario']['url'])
          .to match(%r{/scenarios/#{scenario.id}$})
      end

      it_behaves_like 'updating inputs'
    end

    context 'when providing a balanced single value' do
      before do
        scenario.balanced_values.merge!(
          'balanced_one' => 20.0,
          'balanced_two' => 80.0
        )

        scenario.save!

        nonbalanced_scenario(values: { balanced_one: 100 })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'sets the user value' do
        expect(scenario.user_values).to include('balanced_one' => 100.0)
      end

      it 'removes previously balanced values' do
        expect(scenario.balanced_values).not_to have_key('balanced_one')
        expect(scenario.balanced_values).not_to have_key('balanced_two')
      end

      it_behaves_like 'updating inputs'
    end

    context 'when providing an unbalanced single value' do
      before do
        nonbalanced_scenario(values: { balanced_one: 50 })
      end

      it 'responds 422 Unprocessable Entity' do
        expect(response.status).to be(422)
      end

      it 'does not set the user value' do
        expect(scenario.user_values).not_to have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body))
          .to have_api_balance_error.on(:grouped)
      end
    end

    context 'when providing an unbalanced group' do
      before do
        scenario.balanced_values.merge!(
          'balanced_one' => 20.0,
          'balanced_two' => 80.0
        )

        scenario.save!

        nonbalanced_scenario(values: { balanced_one: 45, balanced_two: 55 })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'sets the user values' do
        expect(scenario.user_values).to include('balanced_one' => 45.0)
        expect(scenario.user_values).to include('balanced_two' => 55.0)
      end

      it 'removes previously balanced values' do
        expect(scenario.balanced_values).not_to have_key('balanced_one')
        expect(scenario.balanced_values).not_to have_key('balanced_two')
      end

      it_behaves_like 'updating inputs'
    end

    context 'when providing a non-balancing single value' do
      before do
        nonbalanced_scenario(values: { balanced_one: 99 })
      end

      it 'responds 422 Unprocessable Entity' do
        expect(response.status).to be(422)
      end

      it 'does not set the user value' do
        expect(scenario.user_values).not_to have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body))
          .to have_api_balance_error.on(:grouped)
      end
    end

    context 'when resetting a member of the group' do
      context 'when the other member is explicitly set' do
        before do
          scenario.user_values.merge!(
            'balanced_one' => 20.0,
            'balanced_two' => 80.0
          )

          scenario.save!

          nonbalanced_scenario(values: { balanced_one: 'reset' })
        end

        it 'responds 422 Unprocessable Entity' do
          expect(response.status).to be(422)
        end

        it 'does not reset the value' do
          expect(scenario.user_values).to include(
            'balanced_one' => 20.0,
            'balanced_two' => 80.0
          )
        end

        it 'warns about the unbalanced group' do
          expect(JSON.parse(response.body))
            .to have_api_balance_error.on(:grouped)
        end
      end

      context 'when the other member is autobalanced' do
        before do
          scenario.user_values['balanced_one'] = 20.0
          scenario.balanced_values['balanced_two'] = 80.0

          scenario.save!

          nonbalanced_scenario(values: { balanced_one: 'reset' })
        end

        it 'responds 200 OK' do
          expect(response.status).to be(200)
        end

        it 'removes the user value' do
          expect(scenario.user_values).not_to have_key('balanced_one')
        end

        it 'removes unnecessary balanced values' do
          expect(scenario.balanced_values).not_to have_key('balanced_two')
        end

        it_behaves_like 'updating inputs'
      end
    end

    context 'when performing a scenario-level reset' do
      before do
        nonbalanced_scenario(params: { reset: true })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'removes the user values' do
        expect(scenario.user_values).to be_empty
      end

      it 'removes the balanced values' do
        expect(scenario.balanced_values).to be_empty
      end
    end
  end

  # --------------------------------------------------------------------------

  context 'when autobalance=true,' do
    context 'when providing one member of a group' do
      before do
        autobalance_scenario(values: { balanced_one: 10 })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'sets the user value' do
        expect(scenario.user_values).to include('balanced_one' => 10.0)
      end

      it 'sets the balanced value' do
        expect(scenario.balanced_values).to include('balanced_two' => 90.0)
      end

      it 'includes the balanaced value when requesting inputs.json' do
        get "/api/v3/scenarios/#{scenario.id}/inputs.json",
          params: '{',
          headers: token_header
        inputs = JSON.parse(response.body)

        expect(inputs['balanced_two']['user']).to be(90.0)
      end

      it_behaves_like 'updating inputs'
    end

    context 'when providing an unbalanceable member of a group' do
      before do
        autobalance_scenario(values: { balanced_one: 101 })
      end

      it 'responds 422 OK' do
        expect(response.status).to be(422)
      end

      it 'sets no user value' do
        expect(scenario.user_values).not_to have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body))
          .to have_api_balance_error.on(:grouped)
      end

      it_behaves_like 'updating inputs'
    end

    context 'when providing all unbalanceable members of a group' do
      before do
        autobalance_scenario(values: { balanced_one: 49, balanced_two: 50 })
      end

      it 'responds 422 OK' do
        expect(response.status).to be(422)
      end

      it 'sets no user value' do
        expect(scenario.user_values).not_to have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body))
          .to have_api_balance_error.on(:grouped)
      end

      it_behaves_like 'updating inputs'
    end

    context 'when providing all members of a group' do
      before do
        autobalance_scenario(values: { balanced_one: 10, balanced_two: 90 })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'sets the user values' do
        expect(scenario.user_values).to include(
          'balanced_one' => 10.0,
          'balanced_two' => 90.0
        )
      end

      it 'does not balance the group' do
        expect(scenario.balanced_values).not_to have_key('balanced_one')
        expect(scenario.balanced_values).not_to have_key('balanced_two')
      end

      it_behaves_like 'updating inputs'
    end

    context 'when resetting a member of the group' do
      context 'when all members are set' do
        before do
          scenario.user_values.merge!(
            'balanced_one' => 90.0,
            'balanced_two' => 10.0
          )

          scenario.save!

          autobalance_scenario(values: { balanced_one: 'reset' })
        end

        it 'responds 200 OK' do
          expect(response.status).to be(200)
        end

        it 're-balances the group' do
          expect(scenario.user_values).to include('balanced_two' => 10.0)
          expect(scenario.user_values).not_to have_key('balanced_one')

          expect(scenario.balanced_values).to include('balanced_one' => 90.0)
        end

        it_behaves_like 'updating inputs'
      end

      context 'when resetting a value specified by the parent scenario' do
        before do
          scenario.preset_scenario_id = parent.id
          scenario.save!

          autobalance_scenario(values: { balanced_one: 'reset' })
        end

        let(:parent) do
          FactoryBot.create(:scenario,
            user_values: { 'balanced_one' => 15.0 },
            balanced_values: { 'balanced_two' => 85.0 })
        end

        it 'responds 200 OK' do
          expect(response.status).to be(200)
        end

        it 'restores the parents user value' do
          expect(scenario.user_values).to include('balanced_one' => 15.0)
        end

        it 'restores the parents balanced value' do
          expect(scenario.balanced_values).to include('balanced_two' => 85.0)
        end

        it_behaves_like 'updating inputs'
      end

      context 'when performing a scenario-level reset and the scenario has a ' \
              'parent' do
        before do
          scenario.preset_scenario_id = parent.id
          scenario.save!

          autobalance_scenario(params: { reset: true })
        end

        let(:parent) do
          FactoryBot.create(:scenario,
            user_values: { 'balanced_one' => 15.0 },
            balanced_values: { 'balanced_two' => 85.0 })
        end

        it 'responds 200 OK' do
          expect(response.status).to be(200)
        end

        it 'restores the parents user values' do
          expect(scenario.user_values).to eq('balanced_one' => 15.0)
        end

        it 'restores the parents balanced values' do
          expect(scenario.balanced_values).to eq('balanced_two' => 85.0)
        end
      end

      context 'when a balanced value is set' do
        before do
          scenario.user_values['balanced_one'] = 90.0
          scenario.balanced_values['balanced_two'] = 10.0
          scenario.save!

          autobalance_scenario(values: { balanced_one: 'reset' })
        end

        it 'responds 200 OK' do
          expect(response.status).to be(200)
        end

        it 'removes the user value' do
          expect(scenario.user_values).not_to have_key('balanced_one')
        end

        it 'removes the balanced value' do
          expect(scenario.balanced_values).not_to have_key('balanced_two')
        end

        it_behaves_like 'updating inputs'
      end

      context 'when only that member is set' do
        before do
          scenario.user_values['balanced_one'] = 100.0
          scenario.save!

          autobalance_scenario(values: { balanced_one: 'reset' })
        end

        it 'responds 200 OK' do
          expect(response.status).to be(200)
        end

        it 'removes the user value' do
          expect(scenario.user_values).not_to have_key('balanced_one')
        end

        it_behaves_like 'updating inputs'
      end
    end

    context 'when resetting all members of the group' do
      before do
        autobalance_scenario(values: { balanced_one: 'reset', balanced_two: 'reset' })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'removes the user values' do
        expect(scenario.user_values).not_to have_key('balanced_one')
        expect(scenario.user_values).not_to have_key('balanced_two')
      end

      it 'does not add any balanced values' do
        expect(scenario.user_values).not_to have_key('balanced_one')
        expect(scenario.balanced_values).not_to have_key('balanced_two')
      end

      it_behaves_like 'updating inputs'
    end

    context 'when performing a scenario-level reset' do
      before do
        autobalance_scenario(params: { reset: true })
      end

      it 'responds 200 OK' do
        expect(response.status).to be(200)
      end

      it 'removes the user values' do
        expect(scenario.user_values).to be_empty
      end

      it 'removes the balanced values' do
        expect(scenario.balanced_values).to be_empty
      end
    end
  end

  # --------------------------------------------------------------------------

  context 'when updating a public scenario owned by someone else' do
    before do
      scenario.delete_all_users
      scenario.update!(user: create(:user))
    end

    it 'returns 403' do
      autobalance_scenario(values: { 'unrelated_one' => 25.0 })
      expect(response.status).to be(403)
    end

    it 'does not update the user values' do
      expect { autobalance_scenario(values: { 'unrelated_one' => 25.0 }) }
        .not_to(change { scenario.reload.user_values })
    end
  end

  context 'when updating their own public scenario' do
    before do
      scenario.delete_all_users
      scenario.update!(user:)

      autobalance_scenario(
        values: { 'unrelated_one' => 25.0 },
        headers: token_header
      )
    end

    let(:user) { create(:user) }

    it 'returns 200' do
      expect(response.status).to be(200)
    end
  end

  context 'when updating their own public scenario without the scenarios:write scope' do
    before do
      user = create(:user)

      scenario.delete_all_users
      scenario.update!(user:)

      autobalance_scenario(
        values: { 'unrelated_one' => 25.0 },
        headers: access_token_header(user, :read)
      )
    end

    it 'returns 403' do
      expect(response.status).to be(403)
    end
  end

  context 'when updating their own private scenario' do
    before do
      autobalance_scenario(
        values: { 'unrelated_one' => 25.0 },
        headers: token_header
      )
    end

    it 'returns 200' do
      expect(response.status).to be(200)
    end
  end

  # --------------------------------------------------------------------------

  context 'with an out-of-range scenario ID' do
    it 'returns 404' do
      put '/api/v3/scenarios/100000000000',
        params: '{',
        headers: access_token_header(create(:user), :read)
      expect(response.status).to be(404)
    end
  end

  context 'when the scenario is invalid' do
    before do
      scenario.area_code = 'invalid'
      scenario.save(validate: false)

      put_scenario(params: { scenario: { end_year: 2030 } }, headers: token_header)
    end

    it 'responds 422' do
      expect(response.status).to be(422)
    end

    it 'has an error message about the scenario' do
      expect(JSON.parse(response.body)['errors'])
        .to include('Scenario area_code is unknown or not supported')
    end
  end

  context 'when the input does not exist' do
    before do
      put_scenario(values: { does_not_exist: 50 }, headers: token_header)
    end

    it 'responds 422 Unprocessable Entity' do
      expect(response.status).to be(422)
    end

    it 'has an error message' do
      expect(JSON.parse(response.body)['errors'])
        .to include('Input does_not_exist does not exist')
    end
  end

  context 'when the value is above the permitted maximum' do
    before do
      put_scenario(values: { nongrouped: 101 }, headers: token_header)
    end

    it 'responds 422 Unprocessable Entity' do
      expect(response.status).to be(422)
    end

    it 'has an error message' do
      expect(JSON.parse(response.body)['errors'])
        .to include('Input nongrouped cannot be greater than 100')
    end
  end

  context 'when the value is beneath the permitted minimum' do
    before do
      put_scenario(values: { nongrouped: -1 }, headers: token_header)
    end

    it 'responds 422 Unprocessable Entity' do
      expect(response.status).to be(422)
    end

    it 'has an error message' do
      expect(JSON.parse(response.body)['errors'])
        .to include('Input nongrouped cannot be less than 0')
    end
  end

  context 'when the value for a boolean input is set' do
    it 'returns 200 for value 0' do
      put_scenario(values: { boolean_one: 0 }, headers: token_header)

      expect(response).to have_http_status(:ok)
    end

    it 'returns 200 for value 1' do
      put_scenario(values: { boolean_one: 1 }, headers: token_header)

      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the value for a boolean input is set to an invalid value' do
    before do
      put_scenario(values: { boolean_one: 1.5 }, headers: token_header)
    end

    it 'responds 422 Unprocessable Entity' do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'has an error message' do
      expect(
        response.parsed_body['errors']
      ).to include(
        "Input 'boolean_one' had value '1.5', but must be one 0 or 1"
      )
    end

    it 'does not set the scenario attributes' do
      expect(scenario.user_values).not_to have_key('boolean_one')
    end
  end

  context 'when requesting a non-existant query' do
    before do
      put_scenario(values: { nongrouped: 10 }, params: { gqueries: %w[does_not_exist] },
        headers: token_header)
    end

    it 'responds 422 Unprocessable Entity' do
      expect(response.status).to be(422)
    end

    it 'has an error message' do
      expect(JSON.parse(response.body)['errors'])
        .to include('Gquery does_not_exist does not exist')
    end

    it 'does not set the scenario attributes' do
      expect(scenario.user_values).not_to have_key('nongrouped')
    end
  end

  context 'when submitting non-Hash user_values' do
    before do
      put "/api/v3/scenarios/#{scenario.id}",
        params: { scenario: { user_values: [] } },
        headers: token_header
    end

    it 'responds 200 OK' do
      expect(response.status).to eq(200)
    end
  end

  context 'when submitting malformed JSON' do
    before do
      put "/api/v3/scenarios/#{scenario.id}",
        params: '{',
        headers: access_token_header(create(:user),
          :read).merge('CONTENT_TYPE' => 'application/json')
    end

    it 'responds 400 Bad Request' do
      expect(response.status).to eq(400)
    end
  end
end
