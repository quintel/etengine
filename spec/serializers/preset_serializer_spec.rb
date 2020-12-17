require 'spec_helper'

describe PresetSerializer do
  let(:controller) { double('Controller', api_v3_scenario_url: 'url') }
  let(:preset)     { FactoryBot.create(:scenario, description: 'Hello!') }

  subject do
    described_class.new(controller, preset).as_json
  end

  it { is_expected.to include(id:          preset.id) }
  it { is_expected.to include(title:       preset.title) }
  it { is_expected.to include(area_code:   preset.area_code) }
  it { is_expected.to include(end_year:    preset.end_year) }
  it { is_expected.to include(description: preset.description) }

  it { is_expected.to include(url: 'url') }

  it 'should ask the controller for the scenario URL' do
    expect(controller).to receive(:api_v3_scenario_url).
      with(preset).and_return('my_url')

    expect(subject[:url]).to eql('my_url')
  end
end
