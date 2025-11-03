# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::PrepareAttributes do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'merges scenario attributes with user and balanced values' do
    allow(scenario).to receive(:attributes).and_return({ 'foo' => 'bar', 'id' => 1, 'created_at' => Time.now, 'updated_at' => Time.now })
    allow(scenario).to receive(:metadata).and_return({ a: 1 })
    scenario_data = { some: 'value', metadata: { b: 2 } }
    result = service.call(scenario, { 'a' => 1 }, { 'b' => 2 }, scenario_data)
    expect(result).to be_success
    expect(result.value!).to include(user_values: { 'a' => 1 }, balanced_values: { 'b' => 2 })
  end
end
