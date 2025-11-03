# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ProcessCouplings do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:service) { described_class.new }

  it 'returns active_couplings as symbols' do
    allow(scenario).to receive(:coupled_inputs).and_return(['a'])
    result = service.call(scenario, {}, ['foo'], false)
    expect(result.value![:active_couplings]).to eq([:foo])
  end

  it 'returns uncoupled_inputs if uncouple is truthy' do
    allow(scenario).to receive(:coupled_inputs).and_return(['a'])
    result = service.call(scenario, {}, [], true)
    expect(result.value![:uncoupled_inputs]).to eq(['a'])
  end
end
