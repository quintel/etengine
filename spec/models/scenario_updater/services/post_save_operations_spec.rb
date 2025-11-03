# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::PostSaveOperations do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'copies preset roles if requested' do
    expect(scenario).to receive(:copy_preset_roles)
    service.call(scenario, true, 'user')
  end

  it 'updates version tag' do
    version_tag = double('VersionTag')
    allow(scenario).to receive(:scenario_version_tag).and_return(version_tag)
    expect(version_tag).to receive(:update).with(user: 'user')
    service.call(scenario, false, 'user')
  end
end
