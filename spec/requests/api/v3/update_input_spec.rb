require 'spec_helper'

describe 'Updating inputs with API v3' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) do
    Factory.create(:scenario,
      user_values:     { 'unrelated_one' => 25.0 },
      balanced_values: { 'unrelated_two' => 75.0 })
  end

  before do
    Input.stub(:records).and_return({
      'balanced_one' =>
        Factory.build(:input, start_value: 100.0, key: 'balanced_one', share_group: 'grouped'),
      'balanced_two' =>
        Factory.build(:input, start_value: 0.0, key: 'balanced_two', share_group: 'grouped'),
      'unrelated_one' =>
        Factory.build(:input, key: 'unrelated_one', share_group: 'diode'),
      'unrelated_two' =>
        Factory.build(:input, key: 'unrelated_two', share_group: 'diode'),
      'nongrouped' =>
        Factory.build(:input, key: 'nongrouped')
    })

    Input.stub(:all).and_return(Input.records.values)
  end

  def put_scenario(user_values = {}, params = {})
    user_values = Hash[user_values.map { |k, v| [ k.to_s, v.to_s ] }]

    put "api/v3/scenarios/#{ scenario.id }",
      params.merge({ scenario: { user_values: user_values } })

    scenario.reload
  end

  def autobalance_scenario(user_values = {}, params = {})
    put_scenario(user_values, params.merge(autobalance: true))
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
    context 'providing a non-grouped single value' do
      before do
        put_scenario(nongrouped: 50)
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'sets the user value' do
        expect(scenario.user_values).to include('nongrouped' => 50.0)
      end

      it 'should include the scenario data' do
        json = JSON.parse(response.body)

        expect(json).to have_key('scenario')

        expect(json['scenario']).to include('title'     => scenario.title)
        expect(json['scenario']).to include('id'        => scenario.id)
        expect(json['scenario']).to include('area_code' => 'nl')
        expect(json['scenario']).to include('end_year'  => scenario.end_year)
        expect(json['scenario']).to include('template'  => nil)
        expect(json['scenario']).to include('source'    => nil)

        expect(json['scenario']).to have_key('created_at')

        expect(json['scenario']['url']).
          to match(%r{/scenarios/#{ scenario.id }$})
      end

      it_should_behave_like 'updating inputs'
    end # providing a non-grouped single value

    context 'providing a balanced single value' do
      before do
        scenario.balanced_values.merge!(
          'balanced_one' => 20.0,
          'balanced_two' => 80.0)

        scenario.save!

        put_scenario(balanced_one: 100)
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'sets the user value' do
        expect(scenario.user_values).to include('balanced_one' => 100.0)
      end

      it 'removes previously balanced values' do
        expect(scenario.balanced_values).to_not have_key('balanced_one')
        expect(scenario.balanced_values).to_not have_key('balanced_two')
      end

      it_should_behave_like 'updating inputs'
    end # providing a balancing single value

    context 'providing an unbalanced single value' do
      before do
        put_scenario(balanced_one: 50)
      end

      it 'responds 422 Unprocessable Entity' do
        expect(response.status).to eql(422)
      end

      it 'does not set the user value' do
        expect(scenario.user_values).to_not have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body)).
          to have_api_balance_error.on(:grouped)
      end
    end # providing a balancing single value

    context 'providing an unbalanced group' do
      before do
        scenario.balanced_values.merge!(
          'balanced_one' => 20.0,
          'balanced_two' => 80.0)

        scenario.save!

        put_scenario(balanced_one: 45, balanced_two: 55)
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'sets the user values' do
        expect(scenario.user_values).to include('balanced_one' => 45.0)
        expect(scenario.user_values).to include('balanced_two' => 55.0)
      end

      it 'removes previously balanced values' do
        expect(scenario.balanced_values).to_not have_key('balanced_one')
        expect(scenario.balanced_values).to_not have_key('balanced_two')
      end

      it_should_behave_like 'updating inputs'
    end # providing a balanced group

    context 'providing a non-balancing single value' do
      before do
        put_scenario(balanced_one: 99)
      end

      it 'responds 422 Unprocessable Entity' do
        expect(response.status).to eql(422)
      end

      it 'does not set the user value' do
        expect(scenario.user_values).to_not have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body)).
          to have_api_balance_error.on(:grouped)
      end
    end # providing a non-balancing single value

    context 'resetting a member of the group' do
      context 'when the other member is explicitly set' do
        before do
          scenario.user_values.merge!(
            'balanced_one' => 20.0,
            'balanced_two' => 80.0)

          scenario.save!

          put_scenario(balanced_one: 'reset')
        end

        it 'responds 422 Unprocessable Entity' do
          expect(response.status).to eql(422)
        end

        it 'does not reset the value' do
          expect(scenario.user_values).to include(
            'balanced_one' => 20.0,
            'balanced_two' => 80.0)
        end

        it 'warns about the unbalanced group' do
          expect(JSON.parse(response.body)).
            to have_api_balance_error.on(:grouped)
        end
      end # when the other member is explicitly set

      context 'when the other member is autobalanced' do
        before do
          scenario.user_values.merge!('balanced_one' => 20.0)
          scenario.balanced_values.merge!('balanced_two' => 80.0)

          scenario.save!

          put_scenario(balanced_one: 'reset')
        end

        it 'responds 200 OK' do
          expect(response.status).to eql(200)
        end

        it 'removes the user value' do
          expect(scenario.user_values).to_not have_key('balanced_one')
        end

        it 'removes unnecessary balanced values' do
          expect(scenario.balanced_values).to_not have_key('balanced_two')
        end

        it_should_behave_like 'updating inputs'
      end # when the other member is autobalanced
    end # resetting a member of the group

    context 'when performing a scenario-level reset' do
      before do
        put_scenario({}, reset: true)
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'should remove the user values' do
        expect(scenario.user_values).to be_empty
      end

      it 'should remove the balanced values' do
        expect(scenario.balanced_values).to be_empty
      end
    end # when performing a scenario-level reset
  end # when autobalance=false

  # --------------------------------------------------------------------------

  context 'when autobalance=true,' do
    context 'providing one member of a group' do
      before do
        autobalance_scenario(balanced_one: 10)
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
        get "api/v3/scenarios/#{ scenario.id }/inputs.json"
        inputs = JSON.parse(response.body)

        inputs['balanced_two']['user'].should eql(90.0)
      end

      it_should_behave_like 'updating inputs'
    end # providing one member of a group

    context 'providing an unbalanceable member of a group' do
      before do
        autobalance_scenario(balanced_one: 101)
      end

      it 'responds 422 OK' do
        expect(response.status).to be(422)
      end

      it 'sets no user value' do
        expect(scenario.user_values).to_not have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body)).
          to have_api_balance_error.on(:grouped)
      end

      it_should_behave_like 'updating inputs'
    end # providing an unbalanceable member of a group

    context 'providing all unbalanceable members of a group' do
      before do
        autobalance_scenario(balanced_one: 49, balanced_two: 50)
      end

      it 'responds 422 OK' do
        expect(response.status).to be(422)
      end

      it 'sets no user value' do
        expect(scenario.user_values).to_not have_key('balanced_one')
      end

      it 'warns about the unbalanced group' do
        expect(JSON.parse(response.body)).
          to have_api_balance_error.on(:grouped)
      end

      it_should_behave_like 'updating inputs'
    end # providing all unbalanceable members of a group

    context 'providing all members of a group' do
      before do
        autobalance_scenario(balanced_one: 10, balanced_two: 90)
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'sets the user values' do
        expect(scenario.user_values).to include(
          'balanced_one' => 10.0,
          'balanced_two' => 90.0)
      end

      it 'does not balance the group' do
        expect(scenario.balanced_values).to_not have_key('balanced_one')
        expect(scenario.balanced_values).to_not have_key('balanced_two')
      end

      it_should_behave_like 'updating inputs'
    end # providing all members of a group

    context 'resetting a member of the group' do
      context 'and all members are set' do
        before do
          scenario.user_values.merge!(
            'balanced_one' => 90.0,
            'balanced_two' => 10.0)

          scenario.save!

          autobalance_scenario(balanced_one: 'reset')
        end

        it 'responds 200 OK' do
          expect(response.status).to eql(200)
        end

        it 're-balances the group' do
          expect(scenario.user_values).to include('balanced_two' => 10.0)
          expect(scenario.user_values).to_not have_key('balanced_one')

          expect(scenario.balanced_values).to include('balanced_one' => 90.0)
        end

        it_should_behave_like 'updating inputs'
      end # and all members are set

      context 'and a balanced value is set' do
        before do
          scenario.user_values.merge!('balanced_one' => 90.0)
          scenario.balanced_values.merge!('balanced_two' => 10.0)
          scenario.save!

          autobalance_scenario(balanced_one: 'reset')
        end

        it 'responds 200 OK' do
          expect(response.status).to eql(200)
        end

        it 'removes the user value' do
          expect(scenario.user_values).to_not have_key('balanced_one')
        end

        it 'removes the balanced value' do
          expect(scenario.balanced_values).to_not have_key('balanced_two')
        end

        it_should_behave_like 'updating inputs'
      end # and a balanced value is set

      context 'and only that member is set' do
        before do
          scenario.user_values.merge!('balanced_one' => 100.0)
          scenario.save!

          autobalance_scenario(balanced_one: 'reset')
        end

        it 'should respond 200 OK' do
          expect(response.status).to eql(200)
        end

        it 'should remove the user value' do
          expect(scenario.user_values).to_not have_key('balanced_one')
        end

        it_should_behave_like 'updating inputs'
      end # and only that member is set
    end # resetting a member of the group

    context 'resetting all members of the group' do
      before do
        autobalance_scenario(balanced_one: 'reset', balanced_two: 'reset')
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'removes the user values' do
        expect(scenario.user_values).to_not have_key('balanced_one')
        expect(scenario.user_values).to_not have_key('balanced_two')
      end

      it 'does not add any balanced values' do
        expect(scenario.user_values).to_not have_key('balanced_one')
        expect(scenario.balanced_values).to_not have_key('balanced_two')
      end

      it_should_behave_like 'updating inputs'
    end # resetting all members of the group

    context 'when performing a scenario-level reset' do
      before do
        autobalance_scenario({}, reset: true)
      end

      it 'responds 200 OK' do
        expect(response.status).to eql(200)
      end

      it 'should remove the user values' do
        expect(scenario.user_values).to be_empty
      end

      it 'should remove the balanced values' do
        expect(scenario.balanced_values).to be_empty
      end
    end # when performing a scenario-level reset
  end # when autobalance=true

  # --------------------------------------------------------------------------

  context 'when the input does not exist' do
    before do
      put_scenario(does_not_exist: 50)
    end

    it 'should respond 422 Unprocessable Entity' do
      expect(response.status).to eql(422)
    end

    it 'should have an error message' do
      expect(JSON.parse(response.body)['errors']).
        to include('Input does_not_exist does not exist')
    end
  end # when the input does not exist

  context 'when the value is above the permitted maximum' do
    before do
      put_scenario(nongrouped: 101)
    end

    it 'should respond 422 Unprocessable Entity' do
      expect(response.status).to eql(422)
    end

    it 'should have an error message' do
      expect(JSON.parse(response.body)['errors']).
        to include("Input nongrouped cannot be greater than 100")
    end
  end # when the value is above the permitted maximum

  context 'when the value is beneath the permitted minimum' do
    before do
      put_scenario(nongrouped: -1)
    end

    it 'should respond 422 Unprocessable Entity' do
      expect(response.status).to eql(422)
    end

    it 'should have an error message' do
      expect(JSON.parse(response.body)['errors']).
        to include("Input nongrouped cannot be less than 0")
    end
  end # when the value is beneath the permitted minimum

  context 'when requesting a non-existent query' do
    before do
      put_scenario({ nongrouped: 10 }, gqueries: %w( does_not_exist ))
    end

    it 'should respond 422 Unprocessable Entity' do
      expect(response.status).to eql(422)
    end

    it 'should have an error message' do
      expect(JSON.parse(response.body)['errors']).
        to include('Gquery does_not_exist does not exist')
    end

    it 'should not set the scenario attributes' do
      expect(scenario.user_values).to_not have_key('nongrouped')
    end
  end # when requesting a non-existent query

end
