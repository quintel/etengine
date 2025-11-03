# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ValidateInputValues do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'returns Success if skip_validation is true' do
    result = service.call(scenario, { 'a' => 1 }, true)
    expect(result).to be_success
  end

  it 'returns Failure if input does not exist' do
    allow(Input).to receive(:get).and_return(nil)
    allow(Input).to receive(:cache).and_return(double(read_many: {}))
    result = service.call(scenario, { 'a' => 1 })
    expect(result).to be_failure
  end
end
