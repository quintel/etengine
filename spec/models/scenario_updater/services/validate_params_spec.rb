# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ValidateParams do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:current_user) { FactoryBot.create(:user) }
  let(:service) { described_class.new }

  describe 'with valid params' do
    it 'returns Success for empty params' do
      result = service.call(scenario, {}, current_user)
      expect(result).to be_success
    end

    it 'returns Success for all valid param types' do
      params = {
        scenario: { user_values: {} },
        reset: true,
        uncouple: false,
        autobalance: 'false',
        force_balance: false,
        gqueries: ['total_co2_emissions']
      }
      result = service.call(scenario, params, current_user)
      expect(result).to be_success
      expect(result.value!).to eq(params)
    end
  end

  describe 'with invalid param types' do
    it 'returns Failure when scenario is not a hash' do
      result = service.call(scenario, { scenario: 'not a hash' }, current_user)
      expect(result).to be_failure
      expect(result.failure[:scenario]).to include('must be a hash')
    end

    it 'returns Failure when reset is not a boolean' do
      result = service.call(scenario, { reset: 'not a bool' }, current_user)
      expect(result).to be_failure
      expect(result.failure[:reset]).to include('must be boolean')
    end

    it 'returns Failure when gqueries is not an array' do
      result = service.call(scenario, { gqueries: 'not an array' }, current_user)
      expect(result).to be_failure
      expect(result.failure[:gqueries]).to include('must be an array')
    end
  end
end
