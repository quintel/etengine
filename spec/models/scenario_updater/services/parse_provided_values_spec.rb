# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ParseProvidedValues do
  let(:scenario) { FactoryBot.create(:scenario, user_values: { 'a' => 1 }, balanced_values: { 'a' => 2 }) }
  let(:service) { described_class.new }

  it 'coerces provided values' do
    input = double('Input', coerce: 42)
    allow(Input).to receive(:get).and_return(input)
    result = service.call(scenario, user_values: { 'a' => '42' })
    expect(result.value!).to eq('a' => 42)
  end

  it 'returns :reset if value is reset and no parent value' do
    allow(Input).to receive(:get).and_return(double('Input', coerce: nil))
    scenario = double('Scenario', parent: nil)
    result = service.call(scenario, user_values: { 'a' => 'reset' })
    expect(result.value!['a']).to eq(:reset)
  end
end
