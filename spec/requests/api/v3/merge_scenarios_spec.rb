require 'spec_helper'

describe 'APIv3 merging scenarios', :etsource_fixture do
  before(:all) do
    NastyCache.instance.expire!
  end

  let!(:scenario_one) do
    FactoryGirl.create(:scenario, {
      user_values:     { 'grouped_input_one' => 25.0 },
      balanced_values: { 'grouped_input_two' => 75.0 }
    })
  end

  let!(:scenario_two) do
    FactoryGirl.create(:scenario, {
      user_values:     { 'grouped_input_one' => 75.0 },
      balanced_values: { 'grouped_input_two' => 25.0 }
    })
  end

  let(:merged) { Scenario.last }
  let(:json)   { JSON.load(response.body) }

  context 'with two scenarios' do
    let(:request) do
      post('/api/v3/scenarios/merge', scenarios: [
        { scenario_id: scenario_one.id, weight: 3.0 },
        { scenario_id: scenario_two.id, weight: 1.0 }
      ])
    end

    it 'creates a new scenario' do
      expect { request }.to change { Scenario.count }.by(1)

      expect(merged.user_values).to     eq('grouped_input_one' => 37.5)
      expect(merged.balanced_values).to eq('grouped_input_two' => 62.5)
    end

    it 'responds with the scenario' do
      request
      expect(json).to have_key('id')
    end
  end # with two scenarios

  context 'with two scenarios and a missing weight' do
    let(:request) do
      post('/api/v3/scenarios/merge', scenarios: [
        { scenario_id: scenario_one.id, weight: 3.0 },
        { scenario_id: scenario_two.id }
      ])
    end

    it 'creates a new scenario' do
      expect { request }.to change { Scenario.count }.by(1)
    end

    it 'responds with the scenario' do
      request
      expect(json).to have_key('id')
    end
  end # with two scenarios and a missing weight

  context "with two scenarios one of which doesn't exist" do
    let(:request) do
      post('/api/v3/scenarios/merge', scenarios: [
        { scenario_id: scenario_one.id, weight: 3.0 },
        { scenario_id: '-1',            weight: 1.0 }
      ])
    end

    it 'does not create a new scenario'
    it 'returns an error response code'
    it 'includes a message about the missing scenario'
  end # with two scenarios one of which doesn't exist

  context 'with only one scenario' do
    let(:request) do
      post('/api/v3/scenarios/merge', scenarios: [
        { scenario_id: scenario_one.id, weight: 3.0 }
      ])
    end

    it 'creates a new scenario' do
      expect { request }.to change { Scenario.count }.by(1)
    end

    it 'responds with the scenario' do
      request
      expect(json).to have_key('id')
    end
  end # with only one scenario

  context 'with no scenarios' do
    let(:request) do
      post('/api/v3/scenarios/merge', scenarios: [])
    end

    it 'does not create a new scenario' do
      expect { request }.to_not change { Scenario.count }
    end

    it 'returns an error response code' do
      request
      expect(response.response_code).to eq(400)
    end

    it 'includes a message about the lack of scenarios' do
      request
      expect(json).to have_key('errors')

      expect(json['errors']['base']).
        to include('You must provide at least one scenario')
    end
  end # with no scenarios

  context 'with a merging error' do
    before do
      scenario_one.area_code = 'eu'
      scenario_one.save!
    end

    let(:request) do
      post('/api/v3/scenarios/merge', scenarios: [
        { scenario_id: scenario_one.id, weight: 3.0 },
        { scenario_id: scenario_two.id, weight: 1.0 }
      ])
    end

    it 'does not create a new scenario' do
      expect { request }.to_not change { Scenario.count }
    end

    it 'returns an error response code' do
      request
      expect(response.response_code).to eq(422)
    end

    it 'includes a message about the lack of scenarios' do
      request
      expect(json).to have_key('errors')

      expect(json['errors']['base']).
        to include('One or more scenarios have differing area codes')
    end
  end # with no scenarios
end # APIv3 merging scenarios
