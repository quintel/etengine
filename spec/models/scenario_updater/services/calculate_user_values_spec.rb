# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::CalculateUserValues do
  let(:scenario) { FactoryBot.create(:scenario, user_values: { 'a' => 1 }) }
  let(:service) { described_class.new }

  it 'merges provided values with base values' do
    result = service.call(scenario, { 'b' => 2 }, [], false)
    expect(result).to be_success
    expect(result.value!).to include('a' => 1, 'b' => 2)
  end

  it 'removes keys with :reset value' do
    result = service.call(scenario, { 'a' => :reset }, [], false)
    expect(result.value!).not_to have_key('a')
  end
end
