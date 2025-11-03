# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::PersistScenario do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'saves scenario and returns Success' do
    allow(scenario).to receive(:attributes=)
    result = service.call(scenario, { foo: 'bar' })
    expect(result).to be_success
  end

  it 'returns Failure if scenario is invalid' do
    allow(scenario).to receive(:attributes=)
    allow(scenario).to receive(:valid?).and_return(false)
    allow(scenario.errors).to receive(:full_messages).and_return(['error'])
    result = service.call(scenario, { foo: 'bar' })
    expect(result).to be_failure
  end
end
