require 'spec_helper'

describe Api::V3::ScenarioPresenter do
  let(:controller) { double('Controller', api_v3_scenario_url: 'url') }
  let(:scenario)   { FactoryGirl.create(:scenario, description: 'Hello!') }

  shared_examples_for 'a scenario presenter' do
    it { should include(id:          scenario.id) }
    it { should include(title:       scenario.title) }
    it { should include(area_code:   scenario.area_code) }
    it { should include(end_year:    scenario.end_year) }
    it { should include(template:    scenario.preset_scenario_id) }
    it { should include(source:      scenario.source) }
    it { should include(created_at:  scenario.created_at) }

    it { should include(url: 'url') }

    it 'should ask the controller for the scenario URL' do
      controller.should_receive(:api_v3_scenario_url).
        with(scenario).and_return('my_url')

      subject[:url].should eql('my_url')
    end
  end

  context 'when "detailed=false"' do
    subject do
      Api::V3::ScenarioPresenter.new(controller, scenario, false).as_json
    end

    it_should_behave_like 'a scenario presenter'

    it { should_not have_key(:description) }
    it { should_not have_key(:use_fce) }
  end

  context 'when "detailed=true"' do
    subject do
      Api::V3::ScenarioPresenter.new(controller, scenario, true).as_json
    end

    it_should_behave_like 'a scenario presenter'

    it { should include(use_fce:     scenario.use_fce) }
    it { should include(description: 'Hello!') }
  end
end # Api::V3::ScenarioPresenter
