# frozen_string_literal: true

require 'spec_helper'

# This action was build to enable projecting cherrypicked sliders from one
# scenario onto the next one.
describe 'APIv3 Scenarios/project', :etsource_fixture do

  let(:scenario_one) do
    FactoryBot.create(:scenario)
  end

  let(:scenario_two) do
    FactoryBot.create(:scenario)
  end

  context 'with valid params' do
    let(:params) do
      { from: scenario_one.id,
        onto: scenario_two.id,
        sliders: [ "input_1" ] }
    end

    subject do
      post '/api/v3/scenarios/project', params: params
      response
    end

    it { is_expected.to have_http_status 200 }

    it 'creates a new scenario' do
      # lets eagerly create the two existing scenarios before counting!
      scenario_one
      scenario_two

      expect { subject }.to change{ Scenario.count }.by 1
    end

    it 'has the id of the newly created scenario in the body' do
      expect(JSON.parse(subject.body)).to have_key("id")
    end
  end

  it 'with invalid params' do
    post '/api/v3/scenarios/project', params: {}
    expect(response.status).to eq(400)
  end

end
