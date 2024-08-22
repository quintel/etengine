# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Scenario::Couplings do
  let(:scenario) { create(:scenario) }

  context 'when the scenario has no couplings' do
    before do
      scenario.user_values = {
        input_disabled_by_coupling: 100
      }
    end

    it 'has no active couplings' do
      expect(scenario.active_couplings).to be_empty
    end

    it 'has no inactive couplings' do
      expect(scenario.inactive_couplings).to be_empty
    end

    it 'has no coupled inputs' do
      expect(scenario.coupled_inputs).to be_empty
    end
  end

  context 'when the scenario has a coupled input set, and the coupling is active' do
    before do
      scenario.user_values = {
        input_disabled_by_coupling: 100,
        input_with_coupling_group: 75
      }

      scenario.activate_coupling(:steel_sector)
    end

    it 'has one active coupling' do
      expect(scenario.active_couplings).to include(:steel_sector)
    end

    it 'has no inactive coupling' do
      expect(scenario.inactive_couplings).to be_empty
    end

    it 'has coupled inputs' do
      expect(scenario.coupled_inputs).not_to be_empty
    end
  end

  context 'when the scenario has a coupled input set, and the coupling is inactive' do
    before do
      scenario.user_values = {
        input_disabled_by_coupling: 100,
        input_with_coupling_group: 75
      }
    end

    it 'has no active coupling' do
      expect(scenario.active_couplings).to be_empty
    end

    it 'has one inactive coupling' do
      expect(scenario.inactive_couplings).to include(:steel_sector)
    end

    it 'has coupled inputs' do
      expect(scenario.coupled_inputs).not_to be_empty
    end
  end

  context 'when activating a non existing coupling' do
    before { scenario.activate_coupling(:party) }

    it 'is invalid' do
      expect(scenario).not_to be_valid
    end
  end
end
