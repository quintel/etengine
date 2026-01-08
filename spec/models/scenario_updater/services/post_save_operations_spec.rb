# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::PostSaveOperations do
  let(:scenario) { create(:scenario) }
  let(:service) { described_class.new }

  it 'copies preset roles if requested' do
    expect(scenario).to receive(:copy_preset_roles).with(nil)
    service.call(scenario, true, nil, 'user')
  end

  it 'copies preset roles with user data' do
    users_data = [{ user_id: 1, user_email: nil, role_id: 3 }]
    expect(scenario).to receive(:copy_preset_roles).with(users_data)
    service.call(scenario, false, users_data, 'user')
  end

  it 'updates version tag' do
    version_tag = double('VersionTag')
    allow(scenario).to receive(:scenario_version_tag).and_return(version_tag)
    expect(version_tag).to receive(:update).with(user: 'user')
    service.call(scenario, false, nil, 'user')
  end
end
