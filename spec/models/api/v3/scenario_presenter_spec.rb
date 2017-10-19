require 'spec_helper'

describe Api::V3::ScenarioPresenter do
  let(:controller) { double('Controller', api_v3_scenario_url: 'url') }
  let(:scenario)   { FactoryGirl.create(:scenario, description: 'Hello!') }

  shared_examples_for 'a scenario presenter' do
    it { is_expected.to include(id:          scenario.id) }
    it { is_expected.to include(title:       scenario.title) }
    it { is_expected.to include(area_code:   scenario.area_code) }
    it { is_expected.to include(end_year:    scenario.end_year) }
    it { is_expected.to include(template:    scenario.preset_scenario_id) }
    it { is_expected.to include(source:      scenario.source) }
    it { is_expected.to include(created_at:  scenario.created_at) }

    it { is_expected.to include(url: 'url') }

    it 'should ask the controller for the scenario URL' do
      expect(controller).to receive(:api_v3_scenario_url).
        with(scenario).and_return('my_url')

      expect(subject[:url]).to eql('my_url')
    end
  end

  context 'when "detailed=false", "include_inputs=false"' do
    subject do
      Api::V3::ScenarioPresenter.new(controller, scenario).as_json
    end

    it_should_behave_like 'a scenario presenter'

    it { is_expected.not_to have_key(:description) }
    it { is_expected.not_to have_key(:use_fce) }
    it { is_expected.not_to have_key(:inputs) }
  end

  context 'when "detailed=true"' do
    subject do
      Api::V3::ScenarioPresenter.new(
        controller, scenario, detailed: true).as_json
    end

    it_should_behave_like 'a scenario presenter'

    it { is_expected.to include(use_fce:     scenario.use_fce) }
    it { is_expected.to include(description: 'Hello!') }
  end

  context 'when "include_inputs=true"' do
    subject do
      Api::V3::ScenarioPresenter.new(
        controller, scenario, include_inputs: true).as_json
    end

    it_should_behave_like 'a scenario presenter'

    it 'should include the default input data' do
      expect(subject).to have_key(:inputs)
      expect(subject[:inputs].keys.sort).to eq(Input.all.map(&:key).sort)
    end
  end
end # Api::V3::ScenarioPresenter
