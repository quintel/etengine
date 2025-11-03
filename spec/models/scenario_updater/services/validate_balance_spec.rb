# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ValidateBalance do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'returns Success if skip_validation is true' do
    result = service.call(scenario, {}, {}, {}, true)
    expect(result).to be_success
  end

  it 'returns Success if all groups sum to 100' do
    input = double('Input', key: 'a', share_group: 'group')
    allow(Input).to receive(:get).and_return(input)
    allow(Input).to receive(:in_share_group).and_return([input])
    allow(Input).to receive(:cache).and_return(double(read: { disabled: false }))
    result = service.call(scenario, { 'a' => 100 }, {}, { 'a' => 100 })
    expect(result).to be_success
  end
end
