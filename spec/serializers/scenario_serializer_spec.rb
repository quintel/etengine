require 'spec_helper'

describe ScenarioSerializer do
  let(:controller) { double('Controller', api_v3_scenario_url: 'url') }
  let(:scenario)   { FactoryBot.create(:scenario) }

  shared_examples_for 'a scenario serializer' do
    it { is_expected.to include(id:          scenario.id) }
    it { is_expected.to include(area_code:   scenario.area_code) }
    it { is_expected.to include(end_year:    scenario.end_year) }
    it { is_expected.to include(template:    scenario.preset_scenario_id) }
    it { is_expected.to include(source:      scenario.source) }
    it { is_expected.to include(created_at:  scenario.created_at) }
    it { is_expected.to include(user_values: scenario.user_values) }
    it { is_expected.to include(metadata: {}) }

    it { is_expected.to include(url: 'url') }

    it 'should ask the controller for the scenario URL' do
      expect(controller).to receive(:api_v3_scenario_url).
        with(scenario).and_return('my_url')

      expect(subject[:url]).to eql('my_url')
    end
  end

  context 'when include_inputs="false"' do
    subject do
      described_class.new(controller, scenario, detailed: 'false', include_inputs: 'false').as_json
    end

    it_should_behave_like 'a scenario serializer'

    it { is_expected.not_to have_key(:inputs) }
  end

  context 'when "include_inputs=true"' do
    subject do
      described_class.new(controller, scenario, include_inputs: true).as_json
    end

    it_should_behave_like 'a scenario serializer'

    it 'should include the default input data' do
      expect(subject).to have_key(:inputs)
      expect(subject[:inputs].keys.sort).to eq(Input.all.map(&:key).sort)
    end
  end

  context 'with a private scenario' do
    subject { described_class.new(controller, scenario).as_json }

    before { scenario.private = true }

    it { is_expected.to include(private: true) }
  end

  context 'with a public scenario' do
    subject { described_class.new(controller, scenario).as_json }

    before { scenario.private = false }

    it { is_expected.to include(private: false) }
  end
end
