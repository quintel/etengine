# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ValidateBalance do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'returns Success if skip_validation is true' do
    result = service.call(
      scenario,
      user_values: {},
      balanced_values: {},
      provided_values: {},
      skip_validation: true
    )
    expect(result).to be_success
  end

  it 'returns Success if all groups sum to 100' do
    input = double('Input', key: 'a', share_group: 'group')
    allow(Input).to receive(:get).and_return(input)
    allow(Input).to receive(:in_share_group).and_return([input])
    allow(Input).to receive(:cache).and_return(double(read: { disabled: false }))
    result = service.call(
      scenario,
      user_values: { 'a' => 100 },
      balanced_values: {},
      provided_values: { 'a' => 100 }
    )
    expect(result).to be_success
  end

  # Reachable when the balancer never saw these values -- force_balance
  # balances the provided values while this service sums the user's, leaving
  # within-tolerance drift that no repair ran on, and so no breach to name.
  context 'with drift within the intent tolerance which no repair was attempted on' do
    let(:values) do
      { 'grouped_input_one' => 60.0, 'grouped_input_two' => 40.0000000001 }
    end

    let(:result) do
      service.call(scenario, user_values: values, balanced_values: {}, provided_values: values)
    end

    it 'returns Failure' do
      expect(result).to be_failure
    end

    it 'reports the imbalance rather than trailing an empty explanation' do
      expect(result.failure.first).to start_with(
        '"grouped" group does not balance: group sums to 100.0000000001 using '
      )
    end

    it 'names every member and its value' do
      expect(result.failure.first)
        .to include('grouped_input_one=60.0', 'grouped_input_two=40.0000000001')
    end

    it 'does not claim a repair was refused' do
      expect(result.failure.first).not_to include('cannot be repaired')
    end
  end
end
