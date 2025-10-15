# frozen_string_literal: true

require 'spec_helper'

# Tests activation and deactivation of input coupling groups.
# Couplings link inputs that should be managed together.
describe ScenarioUpdater::Inputs::CouplingsManager, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:params) { {} }
  let(:current_user) { nil }
  let(:manager) { described_class.new(scenario, params, current_user) }

  before do
    Rails.cache.clear
  end

  # Tests automatic activation of coupling groups when their inputs are provided
  describe '#activate_from_provided_values' do
    context 'when provided values contain no coupling inputs' do
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      before do
        allow(Input).to receive(:coupling_groups_for).with('foo_demand').and_return([])
      end

      it 'does not activate any couplings' do
        expect(scenario).not_to receive(:activate_coupling)
        manager.activate_from_provided_values(provided_values)
      end

      it 'does not change active_couplings' do
        expect { manager.activate_from_provided_values(provided_values) }
          .not_to change { scenario.active_couplings }
      end
    end

    context 'when provided values contain a coupling input' do
      let(:provided_values) { { 'input_with_coupling_group' => 10.0 } }

      before do
        allow(Input).to receive(:coupling_groups_for)
          .with('input_with_coupling_group')
          .and_return(['steel_sector'])
      end

      it 'activates the coupling group' do
        manager.activate_from_provided_values(provided_values)
        expect(scenario.active_couplings).to include('steel_sector')
      end

      it 'calls activate_coupling with the group name' do
        expect(scenario).to receive(:activate_coupling).with('steel_sector')
        manager.activate_from_provided_values(provided_values)
      end
    end

    context 'when provided values contain multiple coupling inputs' do
      let(:provided_values) do
        {
          'input_with_coupling_group' => 10.0,
          'another_coupling_input' => 20.0
        }
      end

      before do
        allow(Input).to receive(:coupling_groups_for)
          .with('input_with_coupling_group')
          .and_return(['steel_sector'])
        allow(Input).to receive(:coupling_groups_for)
          .with('another_coupling_input')
          .and_return(['energy_sector'])
      end

      it 'activates all coupling groups' do
        manager.activate_from_provided_values(provided_values)
        expect(scenario.active_couplings).to include('steel_sector', 'energy_sector')
      end
    end

    context 'when a coupling input belongs to multiple groups' do
      let(:provided_values) { { 'multi_group_input' => 15.0 } }

      before do
        allow(Input).to receive(:coupling_groups_for)
          .with('multi_group_input')
          .and_return(['steel_sector', 'energy_sector'])
      end

      it 'activates all groups' do
        manager.activate_from_provided_values(provided_values)
        expect(scenario.active_couplings).to include('steel_sector', 'energy_sector')
      end
    end

    context 'when a coupling group is already active' do
      let(:provided_values) { { 'input_with_coupling_group' => 10.0 } }

      before do
        allow(Input).to receive(:coupling_groups_for)
          .with('input_with_coupling_group')
          .and_return(['steel_sector'])
        scenario.activate_coupling('steel_sector')
      end

      it 'does not duplicate the coupling' do
        expect { manager.activate_from_provided_values(provided_values) }
          .not_to change { scenario.active_couplings.count }
      end

      it 'still includes the coupling' do
        manager.activate_from_provided_values(provided_values)
        expect(scenario.active_couplings).to include('steel_sector')
      end
    end

    context 'when a coupling group is in inactive_couplings' do
      let(:provided_values) { { 'input_with_coupling_group' => 10.0 } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['input_with_coupling_group'])
        allow(Input).to receive(:coupling_groups_for)
          .with('input_with_coupling_group')
          .and_return(['steel_sector'])

        # Set up the scenario so that the coupling input is present but not activated
        scenario.user_values = { 'input_with_coupling_group' => 5.0 }
      end

      it 'does not activate the coupling' do
        manager.activate_from_provided_values(provided_values)
        expect(scenario.active_couplings).not_to include('steel_sector')
      end

      it 'skips inactive couplings' do
        expect(scenario).not_to receive(:activate_coupling)
        manager.activate_from_provided_values(provided_values)
      end
    end

    context 'when Input.coupling_groups_for returns nil' do
      let(:provided_values) { { 'some_input' => 25.0 } }

      before do
        allow(Input).to receive(:coupling_groups_for)
          .with('some_input')
          .and_return(nil)
      end

      it 'does not raise an error' do
        expect { manager.activate_from_provided_values(provided_values) }
          .not_to raise_error
      end

      it 'does not activate any couplings' do
        expect(scenario).not_to receive(:activate_coupling)
        manager.activate_from_provided_values(provided_values)
      end
    end

    context 'when Input.coupling_groups_for returns an empty array' do
      let(:provided_values) { { 'some_input' => 25.0 } }

      before do
        allow(Input).to receive(:coupling_groups_for)
          .with('some_input')
          .and_return([])
      end

      it 'does not activate any couplings' do
        expect(scenario).not_to receive(:activate_coupling)
        manager.activate_from_provided_values(provided_values)
      end
    end
  end

  # Tests retrieval of inputs that should be removed when uncoupling
  describe '#uncoupled_inputs' do
    context 'when uncouple parameter is not set' do
      let(:params) { {} }

      it 'returns an empty array' do
        expect(manager.uncoupled_inputs).to eq([])
      end
    end

    context 'when uncouple parameter is false' do
      let(:params) { { uncouple: false } }

      it 'returns an empty array' do
        expect(manager.uncoupled_inputs).to eq([])
      end
    end

    context 'when uncouple parameter is true' do
      let(:params) { { uncouple: true } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['input_with_coupling_group'])
        scenario.user_values = {
          'foo_demand' => 50.0,
          'input_with_coupling_group' => 10.0
        }
      end

      it 'returns the coupled inputs from the scenario' do
        expect(manager.uncoupled_inputs).to eq(['input_with_coupling_group'])
      end

      it 'calls coupled_inputs on the scenario' do
        expect(scenario).to receive(:coupled_inputs).and_call_original
        manager.uncoupled_inputs
      end
    end

    context 'when uncouple parameter is the string "true"' do
      let(:params) { { uncouple: 'true' } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['input_with_coupling_group'])
        scenario.user_values = { 'input_with_coupling_group' => 10.0 }
      end

      it 'returns the coupled inputs' do
        expect(manager.uncoupled_inputs).to eq(['input_with_coupling_group'])
      end
    end

    context 'when uncouple parameter is the string "1"' do
      let(:params) { { uncouple: '1' } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['input_with_coupling_group'])
        scenario.user_values = { 'input_with_coupling_group' => 10.0 }
      end

      it 'returns the coupled inputs' do
        expect(manager.uncoupled_inputs).to eq(['input_with_coupling_group'])
      end
    end

    context 'when uncouple parameter is any other value' do
      let(:params) { { uncouple: 'false' } }

      it 'returns an empty array' do
        expect(manager.uncoupled_inputs).to eq([])
      end
    end

    context 'when uncouple is true but scenario has no coupled inputs' do
      let(:params) { { uncouple: true } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return([])
        scenario.user_values = { 'foo_demand' => 50.0 }
      end

      it 'returns an empty array' do
        expect(manager.uncoupled_inputs).to eq([])
      end
    end
  end

  describe 'TRUTHY_VALUES constant' do
    it 'includes true' do
      expect(described_class::TRUTHY_VALUES).to include(true)
    end

    it 'includes the string "true"' do
      expect(described_class::TRUTHY_VALUES).to include('true')
    end

    it 'includes the string "1"' do
      expect(described_class::TRUTHY_VALUES).to include('1')
    end

    it 'does not include false' do
      expect(described_class::TRUTHY_VALUES).not_to include(false)
    end

    it 'does not include the string "false"' do
      expect(described_class::TRUTHY_VALUES).not_to include('false')
    end

    it 'does not include 1 as an integer' do
      expect(described_class::TRUTHY_VALUES).not_to include(1)
    end
  end
end
