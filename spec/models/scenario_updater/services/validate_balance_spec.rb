# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ValidateBalance do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  def balance(share_of_second_input)
    values = { 'grouped_input_one' => 60, 'grouped_input_two' => share_of_second_input }
    service.call(scenario, user_values: values, balanced_values: {}, provided_values: values)
  end

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

  it 'returns Success when a share group sums to exactly 100' do
    expect(balance(40)).to be_success
  end

  it 'returns Success when a share group sum has floating point drift (regression for pyetm#197)' do
    expect(balance(40.0000000001)).to be_success
  end

  it 'returns Success when a share group sum is within tolerance of 100' do
    expect(balance(40 - (described_class::TOLERANCE / 2))).to be_success
  end

  it 'returns Failure when a share group sum is outside tolerance of 100' do
    expect(balance(40 - (described_class::TOLERANCE * 2))).to be_failure
  end

  it 'includes the group name, sum, and contributing input values in the failure message' do
    result = balance(39)
    expect(result.failure.first).to eq(
      '"grouped" group does not balance: group sums to 99 using ' \
      'grouped_input_one=60 grouped_input_two=39'
    )
  end
end
