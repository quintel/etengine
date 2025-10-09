require 'spec_helper'

describe ScenarioSerializer do
  let(:controller) { double('Controller') }
  let(:scenario)   { FactoryBot.create(:scenario) }
  let(:expected_url) { "#{Settings.etmodel}/scenarios/#{scenario.id}" }

  shared_examples_for 'a scenario serializer' do
    it { is_expected.to include(id: scenario.id) }
    it { is_expected.to include(area_code: scenario.area_code) }
    it { is_expected.to include(end_year: scenario.end_year) }
    it { is_expected.to include(template: scenario.preset_scenario_id) }
    it { is_expected.to include(source: scenario.source) }
    it { is_expected.to include(created_at: scenario.created_at) }
    it { is_expected.to include(user_values: scenario.user_values) }
    it { is_expected.to include(balanced_values: scenario.balanced_values) }
    it { is_expected.to include(metadata: {}) }

    it { is_expected.to include(url: expected_url) }
  end

  context 'when serializing a scenario' do
    subject do
      described_class.new(controller, scenario).as_json
    end

    it_should_behave_like 'a scenario serializer'

    it { is_expected.not_to have_key(:inputs) }
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
