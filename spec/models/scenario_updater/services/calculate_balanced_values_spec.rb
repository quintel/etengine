# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::CalculateBalancedValues do
  let(:scenario) { FactoryBot.create(:scenario, balanced_values: { 'a' => 10 }) }
  let(:service) { described_class.new }

  it 'returns Success with empty hash if user_values is blank' do
    result = service.call(
      scenario,
      user_values: {},
      provided_values: {},
      uncoupled_inputs: [],
      reset: false,
      autobalance: false,
      force_balance: false
    )
    expect(result).to be_success
    expect(result.value!).to eq({})
  end

  it 'removes balanced values for groups being updated' do
    allow(Input).to receive(:get).and_return(double('Input', share_group: 'group'))
    allow(Input).to receive(:in_share_group).and_return([double('Input', key: 'a')])
    result = service.call(
      scenario,
      user_values: { 'a' => 1 },
      provided_values: { 'a' => 1 },
      uncoupled_inputs: [],
      reset: false,
      autobalance: false,
      force_balance: false
    )
    expect(result).to be_success
  end
end
