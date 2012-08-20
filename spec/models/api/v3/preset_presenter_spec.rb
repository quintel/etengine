require 'spec_helper'

describe Api::V3::PresetPresenter do
  let(:controller) { double('Controller', api_v3_scenario_url: 'url') }
  let(:preset)     { FactoryGirl.create(:scenario, description: 'Hello!') }

  subject do
    Api::V3::PresetPresenter.new(controller, preset).as_json
  end

  it { should include(id:          preset.id) }
  it { should include(title:       preset.title) }
  it { should include(area_code:   preset.area_code) }
  it { should include(end_year:    preset.end_year) }
  it { should include(description: preset.description) }

  it { should include(url: 'url') }

  it 'should ask the controller for the scenario URL' do
    controller.should_receive(:api_v3_scenario_url).
      with(preset).and_return('my_url')

    subject[:url].should eql('my_url')
  end
end # Api::V3::PresetPresenter
