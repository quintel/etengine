# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ApplyCouplings do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'activates couplings from active_couplings' do
    expect(scenario).to receive(:activate_coupling).with(:foo)
    result = service.call(scenario, { active_couplings: [:foo], couplings_to_activate: [] })
    expect(result).to be_success
  end

  it 'activates couplings from couplings_to_activate' do
    expect(scenario).to receive(:activate_coupling).with(:bar)
    result = service.call(scenario, { couplings_to_activate: [:bar] })
    expect(result).to be_success
  end
end
