require 'spec_helper'

describe 'APIv3 input update' do
  before(:all) do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:json)     { JSON.parse(response.body) }
  let(:errors)   { json['errors'] || [] }

  # --------------------------------------------------------------------------

  context 'when updating a valid input' do
    before do
      put "api/v3/scenarios/#{ scenario.id }",
        scenario: { user_values: { 'foo_demand' => 50 } }
    end

    it 'should update the input' do
      scenario.reload.user_values['foo_demand'].should eql(50.0)
    end

    it 'should respond 200 OK' do
      response.status.should eql(200)
    end

    it 'should include the scenario data' do
      json.should have_key('scenario')

      json['scenario'].should include('title'      => scenario.title)
      json['scenario'].should include('id'         => scenario.id)
      json['scenario'].should include('area_code'  => 'nl')
      json['scenario'].should include('end_year'   => scenario.end_year)
      json['scenario'].should include('template'   => nil)
      json['scenario'].should include('source'     => nil)

      json['scenario'].should have_key('created_at')

      json['scenario']['url'].should match(%r{/scenarios/#{ scenario.id }$})
    end
  end # when updating a valid input

  # --------------------------------------------------------------------------

  context 'when the input does not exist' do
    before do
      put "api/v3/scenarios/#{ scenario.id }",
        scenario: { user_values: { 'does_not_exist' => 50 } }
    end

    pending 'should respond 422 Unprocessable Entity' do
      response.status.should eql(422)
    end

    it 'should have an error message' do
      json['errors'].should include('Missing input: does_not_exist')
    end
  end # when the input does not exist

  # --------------------------------------------------------------------------

  context 'when the value is above the permitted maximum' do
    before do
      put "api/v3/scenarios/#{ scenario.id }",
        scenario: { user_values: { 'foo_demand' => 101 } }
    end

    pending 'should respond 422 Unprocessable Entity' do
      response.status.should eql(422)
    end

    pending 'should have an error message' do
      errors.should include("Input foo_demand can't be greater than 100")
    end
  end # when the value is above the permitted maximum

  # --------------------------------------------------------------------------

  context 'when the value is beneath the permitted minimum' do
    before do
      put "api/v3/scenarios/#{ scenario.id }",
        scenario: { user_values: { 'foo_demand' => -1 } }
    end

    pending 'should respond 422 Unprocessable Entity' do
      response.status.should eql(422)
    end

    pending 'should have an error message' do
      errors.should include("Input foo_demand can't be less than 0")
    end
  end # when the value is beneath the permitted minimum

  # --------------------------------------------------------------------------

  context 'when resetting a single value' do
    before do
      scenario.user_values['foo_demand'] = 50.0
      scenario.user_values['foo_demand'] = 25.0
      scenario.save!

      put "api/v3/scenarios/#{ scenario.id }",
        scenario: { user_values: { 'foo_demand' => 'reset' } }
    end

    it 'should respond 200 OK' do
      response.status.should eql(200)
    end

    it 'should remove the user value' do
      scenario.reload

      scenario.user_values.should_not have_key('foo_demand')

      pending 'Not sure if this is expected behaviour?' do
        scenario.user_values.should include('bar_demand' => 25.0)
      end
    end
  end # when resetting a single value

  # --------------------------------------------------------------------------

  context 'when resetting the entire scenario' do
    before do
      scenario.user_values['foo_demand'] = 50.0
      scenario.user_values['bar_demand'] = 25.0
      scenario.save!

      put "api/v3/scenarios/#{ scenario.id }", reset: true
    end

    it 'should respond 200 OK' do
      response.status.should eql(200)
    end

    it 'should remove all user values' do
      scenario.reload
      scenario.user_values.should be_empty
    end
  end # when resetting the entire scenario

  # --------------------------------------------------------------------------

  context 'when no value is given' do
    before do
      put "api/v3/scenarios/#{ scenario.id }",
        scenario: { user_values: { 'foo_demand' => '' } }
    end

    pending 'should respond 422 Unprocessable Entity' do
      response.status.should eql(422)
    end

    pending 'should have an error message' do
      errors.should include('Input foo_demand is not valid')
    end
  end # when no value is given

end
