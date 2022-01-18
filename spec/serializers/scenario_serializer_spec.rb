require 'spec_helper'

describe ScenarioSerializer do
  let(:controller) { double('Controller', api_v3_scenario_url: 'url') }
  let(:scenario)   { FactoryBot.create(:scenario, description: 'Hello!') }

  shared_examples_for 'a scenario serializer' do
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
      described_class.new(controller, scenario).as_json
    end

    it_should_behave_like 'a scenario serializer'

    it { is_expected.not_to have_key(:description) }
    it { is_expected.not_to have_key(:inputs) }
  end

  context 'when "detailed=true"' do
    subject do
      described_class.new(controller, scenario, detailed: true).as_json
    end

    it_should_behave_like 'a scenario serializer'

    it { is_expected.to include(description: 'Hello!') }

    it { is_expected.to include(metadata: {}) }
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

  context 'with an unprotected scenario' do
    subject { described_class.new(controller, scenario).as_json }

    before { scenario.update!(protected: false) }

    it { is_expected.to include(protected: false) }
  end

  context 'with a protected scenario' do
    subject { described_class.new(controller, scenario).as_json }

    before { scenario.update!(protected: true) }

    it { is_expected.to include(protected: true) }
  end
end
