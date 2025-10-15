# frozen_string_literal: true

require 'spec_helper'

# Tests the main ScenarioUpdater orchestrator that:
# - Initializes couplings manager and inputs update components
# - Applies couplings (from active_couplings list and provided values)
# - Processes and validates input updates
# - Merges scenario attributes and saves
# - Handles post-save operations (preset roles, version tags)
describe ScenarioUpdater, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:params) { {} }
  let(:current_user) { nil }
  let(:updater) { described_class.new(scenario, params, current_user) }

  before do
    Rails.cache.clear
  end

  # ============================================================================
  # Shared Examples
  # ============================================================================

  shared_examples_for 'a successful apply' do
    it 'returns true' do
      expect(updater.apply).to be true
    end

    it 'has no errors' do
      updater.apply
      expect(updater.errors).to be_blank
    end
  end

  shared_examples_for 'a failed apply' do
    it 'returns false' do
      expect(updater.apply).to be false
    end

    it 'does not save the scenario' do
      original_updated_at = scenario.updated_at
      updater.apply
      expect(scenario.reload.updated_at).to eq(original_updated_at)
    end

    it 'has errors' do
      updater.apply
      expect(updater.errors).not_to be_blank
    end
  end

  # ============================================================================
  # Initialization
  # ============================================================================

  describe '#initialize' do
    it 'sets the scenario' do
      expect(updater.scenario).to eq(scenario)
    end

    it 'initializes errors' do
      expect(updater.errors).to be_a(ActiveModel::Errors)
    end

    it 'initializes couplings manager' do
      expect(updater.instance_variable_get(:@couplings_manager))
        .to be_a(ScenarioUpdater::Inputs::CouplingsManager)
    end

    it 'initializes inputs update' do
      expect(updater.instance_variable_get(:@inputs_update))
        .to be_a(ScenarioUpdater::Inputs::Update)
    end

    context 'with a current user' do
      let(:current_user) { double('User', id: 123) }

      it 'passes current_user to components' do
        expect(updater.instance_variable_get(:@current_user)).to eq(current_user)
      end
    end

    context 'with nil current_user' do
      let(:current_user) { nil }

      it 'accepts nil current_user' do
        expect(updater.instance_variable_get(:@current_user)).to be_nil
      end
    end
  end

  # ============================================================================
  # #apply - Main Orchestration Method
  # ============================================================================

  describe '#apply' do
    # --------------------------------------------------------------------------
    # Empty params
    # --------------------------------------------------------------------------

    context 'with empty params' do
      let(:params) { {} }

      it 'returns true immediately' do
        expect(updater.apply).to be true
      end

      it 'does not process inputs' do
        inputs_update = updater.instance_variable_get(:@inputs_update)
        expect(inputs_update).not_to receive(:process)
        updater.apply
      end

      it 'does not save the scenario' do
        expect(scenario).not_to receive(:save)
        updater.apply
      end
    end

    # --------------------------------------------------------------------------
    # Valid updates
    # --------------------------------------------------------------------------

    context 'with valid input values' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it_behaves_like 'a successful apply'

      it 'updates user_values on the scenario' do
        updater.apply
        expect(scenario.user_values).to include('foo_demand' => 50.0)
      end

      it 'updates balanced_values on the scenario' do
        updater.apply
        expect(scenario.balanced_values).to be_a(Hash)
      end
    end

    context 'with valid scenario attributes' do
      let(:params) do
        {
          scenario: {
            private: true,
            keep_compatible: true,
            source: 'test_source'
          }
        }
      end

      it_behaves_like 'a successful apply'

      it 'updates scenario private flag' do
        updater.apply
        expect(scenario.reload.private).to be true
      end

      it 'updates scenario keep_compatible flag' do
        updater.apply
        expect(scenario.reload.keep_compatible).to be true
      end

      it 'updates scenario source' do
        updater.apply
        expect(scenario.reload.source).to eq('test_source')
      end
    end

    context 'with both input values and scenario attributes' do
      let(:params) do
        {
          scenario: {
            private: true,
            user_values: { 'foo_demand' => '75.0' }
          }
        }
      end

      it_behaves_like 'a successful apply'

      it 'updates both private flag and user_values' do
        updater.apply
        scenario.reload
        expect(scenario.private).to be true
        expect(scenario.user_values['foo_demand']).to eq(75.0)
      end
    end

    # --------------------------------------------------------------------------
    # Invalid updates
    # --------------------------------------------------------------------------

    context 'with invalid input values' do
      let(:params) do
        {
          scenario: {
            user_values: { 'nonexistent_input' => '100.0' }
          }
        }
      end

      it_behaves_like 'a failed apply'

      it 'includes input errors' do
        updater.apply
        expect(updater.errors.full_messages.join(', ')).to include('nonexistent_input')
      end
    end

    context 'with invalid scenario attributes causing save failure' do
      before do
        # Stub save to return false
        allow(scenario).to receive(:save).and_return(false)
      end

      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it 'returns false' do
        expect(updater.apply).to be false
      end
    end

    context 'when validation fails' do
      before do
        allow(updater).to receive(:valid?).and_return(false)
        updater.errors.add(:base, 'Validation error')
      end

      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it 'returns false' do
        expect(updater.apply).to be false
      end

      it 'does not save the scenario' do
        expect(scenario).not_to receive(:save)
        updater.apply
      end
    end

    context 'when scenario save fails' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      before do
        allow(scenario).to receive(:save).and_return(false)
      end

      it 'returns false' do
        expect(updater.apply).to be false
      end
    end

    # --------------------------------------------------------------------------
    # Metadata handling
    # --------------------------------------------------------------------------

    context 'with metadata in params' do
      let(:params) do
        {
          scenario: {
            metadata: { 'custom_key' => 'custom_value' }
          }
        }
      end

      it_behaves_like 'a successful apply'

      it 'updates scenario metadata' do
        updater.apply
        expect(scenario.reload.metadata).to include('custom_key' => 'custom_value')
      end
    end

    context 'without metadata in params' do
      let(:scenario) do
        FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050, metadata: { 'existing' => 'data' })
      end

      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      it 'preserves existing metadata' do
        updater.apply
        expect(scenario.reload.metadata).to include('existing' => 'data')
      end
    end

    # --------------------------------------------------------------------------
    # Preset roles
    # --------------------------------------------------------------------------

    context 'with set_preset_roles: true' do
      let(:params) do
        {
          scenario: {
            set_preset_roles: true
          }
        }
      end

      it 'calls copy_preset_roles on the scenario' do
        expect(scenario).to receive(:copy_preset_roles)
        updater.apply
      end
    end

    context 'with set_preset_roles: "true"' do
      let(:params) do
        {
          scenario: {
            set_preset_roles: 'true'
          }
        }
      end

      it 'calls copy_preset_roles on the scenario' do
        expect(scenario).to receive(:copy_preset_roles)
        updater.apply
      end
    end

    context 'with set_preset_roles: "1"' do
      let(:params) do
        {
          scenario: {
            set_preset_roles: '1'
          }
        }
      end

      it 'calls copy_preset_roles on the scenario' do
        expect(scenario).to receive(:copy_preset_roles)
        updater.apply
      end
    end

    context 'with set_preset_roles: false' do
      let(:params) do
        {
          scenario: {
            set_preset_roles: false
          }
        }
      end

      it 'does not call copy_preset_roles' do
        expect(scenario).not_to receive(:copy_preset_roles)
        updater.apply
      end
    end

    context 'without set_preset_roles param' do
      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      it 'does not call copy_preset_roles' do
        expect(scenario).not_to receive(:copy_preset_roles)
        updater.apply
      end
    end

    # --------------------------------------------------------------------------
    # Scenario version tag
    # --------------------------------------------------------------------------

    context 'with a scenario_version_tag present' do
      let(:current_user) { double('User', id: 123, email: 'test@example.com') }
      let(:version_tag) { double('ScenarioVersionTag', update: true) }

      before do
        allow(scenario).to receive(:scenario_version_tag).and_return(version_tag)
      end

      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it 'updates the version tag with current user' do
        expect(version_tag).to receive(:update).with(user: current_user)
        updater.apply
      end
    end

    context 'without a scenario_version_tag' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      before do
        allow(scenario).to receive(:scenario_version_tag).and_return(nil)
      end

      it 'does not raise an error' do
        expect { updater.apply }.not_to raise_error
      end

      it_behaves_like 'a successful apply'
    end

    # --------------------------------------------------------------------------
    # Attribute filtering
    # --------------------------------------------------------------------------

    context 'when params include protected attributes' do
      let(:params) do
        {
          scenario: {
            area_code: 'de',  # Should be filtered
            end_year: 2060,   # Should be filtered
            private: true     # Should be allowed
          }
        }
      end

      it 'does not update area_code' do
        original_area_code = scenario.area_code
        updater.apply
        expect(scenario.reload.area_code).to eq(original_area_code)
      end

      it 'does not update end_year' do
        original_end_year = scenario.end_year
        updater.apply
        expect(scenario.reload.end_year).to eq(original_end_year)
      end

      it 'updates allowed attributes' do
        updater.apply
        expect(scenario.reload.private).to be true
      end
    end

    context 'when params include user_values at scenario level' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' },
            private: true
          }
        }
      end

      it 'filters out user_values from attributes_to_apply' do
        updater.apply
        # user_values should be set via @inputs_update, not directly from params
        expect(scenario.reload.private).to be true
      end

      it 'still processes user_values through inputs system' do
        updater.apply
        expect(scenario.reload.user_values['foo_demand']).to eq(50.0)
      end
    end

    # --------------------------------------------------------------------------
    # Couplings
    # --------------------------------------------------------------------------

    context 'with active couplings in params' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          },
          active_couplings: ['coupling_1', 'coupling_2']
        }
      end

      it 'applies active couplings via couplings manager' do
        couplings_manager = updater.instance_variable_get(:@couplings_manager)
        expect(couplings_manager).to receive(:apply_active_couplings_list!)
        updater.apply
      end
    end

    context 'with input values that trigger couplings' do
      let(:params) do
        {
          scenario: {
            user_values: {
              'foo_demand' => '50.0',
              'input_2' => '75.0'
            }
          }
        }
      end

      it 'activates couplings from provided values' do
        couplings_manager = updater.instance_variable_get(:@couplings_manager)
        expect(couplings_manager).to receive(:activate_from_provided_values)
        updater.apply
      end
    end
  end

  # ============================================================================
  # #valid? - Validation Method
  # ============================================================================

  describe '#valid?' do
    context 'with valid scenario and inputs' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      before do
        updater.instance_variable_get(:@inputs_update).process
      end

      it 'returns true' do
        expect(updater.valid?).to be true
      end

      it 'has no errors' do
        updater.valid?
        expect(updater.errors).to be_blank
      end
    end

    context 'with invalid inputs' do
      let(:params) do
        {
          scenario: {
            user_values: { 'nonexistent_input' => '100.0' }
          }
        }
      end

      before do
        updater.instance_variable_get(:@inputs_update).process
      end

      it 'returns false' do
        expect(updater.valid?).to be false
      end

      it 'aggregates input errors' do
        updater.valid?
        expect(updater.errors).not_to be_blank
      end
    end

    context 'with scenario that fails validation' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      before do
        # Process inputs first to initialize validators
        updater.instance_variable_get(:@inputs_update).process
        # Make scenario invalid by clearing a required field
        scenario.area_code = nil
      end

      it 'returns false' do
        expect(updater.valid?).to be false
      end

      it 'includes scenario validation errors' do
        updater.valid?
        # Error message will be about dataset key (nil area_code) or area_code directly
        expect(updater.errors.full_messages.join).to match(/dataset.*key.*nil|area_code/i)
      end
    end

    context 'when validation raises a RuntimeError' do
      before do
        inputs_update = updater.instance_variable_get(:@inputs_update)
        allow(inputs_update).to receive(:valid?).and_raise(RuntimeError, 'Validation failed')
      end

      it 'returns false' do
        expect(updater.valid?).to be false
      end

      it 'captures the error message' do
        updater.valid?
        expect(updater.errors[:base]).to include('Validation failed')
      end
    end

    context 'with multiple validation errors' do
      let(:params) do
        {
          scenario: {
            user_values: { 'nonexistent_input' => '100.0' }
          }
        }
      end

      before do
        updater.instance_variable_get(:@inputs_update).process
        scenario.area_code = nil
      end

      it 'returns false' do
        expect(updater.valid?).to be false
      end

      it 'aggregates all errors' do
        updater.valid?
        # Should have errors (exact count may vary based on validation logic)
        expect(updater.errors.count).to be > 0
        expect(updater.errors.full_messages).not_to be_empty
      end
    end

    context 'error aggregation from components' do
      let(:params) do
        {
          scenario: {
            user_values: { 'nonexistent_input' => '100.0' }
          }
        }
      end

      before do
        inputs_update = updater.instance_variable_get(:@inputs_update)
        inputs_update.process
        inputs_update.errors.add(:base, 'Custom input error')
      end

      it 'includes errors from inputs_update' do
        updater.valid?
        expect(updater.errors.full_messages).to include('Custom input error')
      end
    end
  end

  # ============================================================================
  # Integration Tests - Complete Workflows
  # ============================================================================

  describe 'complete update workflow' do
    context 'updating a scenario with multiple changes' do
      let(:params) do
        {
          scenario: {
            private: true,
            keep_compatible: true,
            source: 'integration_test',
            user_values: {
              'foo_demand' => '60.0',
              'input_2' => '80.0'
            },
            metadata: {
              'source' => 'api_test',
              'version' => '2.0'
            }
          }
        }
      end

      it 'successfully applies all changes' do
        expect(updater.apply).to be true

        scenario.reload
        expect(scenario.private).to be true
        expect(scenario.keep_compatible).to be true
        expect(scenario.source).to eq('integration_test')
        expect(scenario.user_values['foo_demand']).to eq(60.0)
        expect(scenario.user_values['input_2']).to eq(80.0)
        expect(scenario.metadata['source']).to eq('api_test')
        expect(scenario.metadata['version']).to eq('2.0')
      end
    end

    context 'partial update with existing values' do
      let(:scenario) do
        FactoryBot.create(
          :scenario,
          area_code: 'nl',
          end_year: 2050,
          private: false,
          user_values: { 'foo_demand' => 30.0 },
          metadata: { 'existing_key' => 'existing_value' }
        )
      end

      let(:params) do
        {
          scenario: {
            private: true,
            user_values: { 'input_2' => '90.0' }
          }
        }
      end

      it 'merges new values with existing ones' do
        updater.apply
        scenario.reload

        expect(scenario.private).to be true
        expect(scenario.user_values['foo_demand']).to eq(30.0)
        expect(scenario.user_values['input_2']).to eq(90.0)
        expect(scenario.metadata['existing_key']).to eq('existing_value')
      end
    end

    context 'resetting input values' do
      let(:scenario) do
        FactoryBot.create(
          :scenario_with_user_values,
          area_code: 'nl',
          end_year: 2050
        )
      end

      let(:params) do
        {
          scenario: {
            user_values: {
              'foo_demand' => 'reset'
            }
          }
        }
      end

      it 'removes the reset input from user_values' do
        updater.apply
        expect(scenario.reload.user_values['foo_demand']).to be_nil
      end
    end
  end

  # ============================================================================
  # Edge Cases and Error Handling
  # ============================================================================

  describe 'edge cases' do
    context 'with nil params' do
      let(:updater) { described_class.new(scenario, nil, current_user) }

      it 'raises an error on apply' do
        expect { updater.apply }.to raise_error(NoMethodError)
      end
    end

    context 'with nested hash params' do
      let(:params) do
        {
          scenario: {
            user_values: {
              'foo_demand' => '50.0'
            },
            metadata: {
              'nested' => {
                'deeply' => {
                  'value' => 'test'
                }
              }
            }
          }
        }
      end

      it 'handles nested structures correctly' do
        expect(updater.apply).to be true
        expect(scenario.reload.metadata.dig('nested', 'deeply', 'value')).to eq('test')
      end
    end

    context 'with indifferent access on params' do
      let(:params) do
        {
          'scenario' => {
            'private' => true,
            'user_values' => { 'foo_demand' => '50.0' }
          }
        }.with_indifferent_access
      end

      it 'handles string keys correctly' do
        expect(updater.apply).to be true
        expect(scenario.reload.private).to be true
      end
    end

    context 'when scenario is not yet persisted' do
      let(:scenario) { FactoryBot.build(:scenario, area_code: 'nl', end_year: 2050) }
      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      it 'saves the new scenario' do
        expect { updater.apply }.to change { Scenario.count }.by(1)
      end
    end

    context 'with concurrent updates' do
      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      before do
        # Simulate another process updating the scenario
        scenario.update_column(:source, 'Updated by another process')
      end

      it 'overwrites with the new values' do
        updater.apply
        expect(scenario.reload.private).to be true
      end
    end
  end

  # ============================================================================
  # Component Interaction Tests
  # ============================================================================

  describe 'component interactions' do
    let(:params) do
      {
        scenario: {
          user_values: { 'foo_demand' => '50.0' }
        }
      }
    end

    it 'processes inputs before validation' do
      inputs_update = updater.instance_variable_get(:@inputs_update)

      expect(inputs_update).to receive(:process).ordered.and_call_original
      expect(updater).to receive(:valid?).ordered.and_call_original

      updater.apply
    end

    it 'validates before saving' do
      expect(updater).to receive(:valid?).ordered.and_return(true)
      expect(scenario).to receive(:save).ordered.and_call_original

      updater.apply
    end

    it 'does not save if validation fails' do
      allow(updater).to receive(:valid?).and_return(false)

      expect(scenario).not_to receive(:save)
      updater.apply
    end

    it 'passes couplings_manager to inputs_update' do
      couplings_manager = updater.instance_variable_get(:@couplings_manager)
      inputs_update = updater.instance_variable_get(:@inputs_update)

      expect(inputs_update.instance_variable_get(:@couplings_manager)).to eq(couplings_manager)
    end
  end

  # ============================================================================
  # Performance and Optimization Tests
  # ============================================================================

  describe 'performance considerations' do
    context 'with empty params' do
      let(:params) { {} }

      it 'short-circuits without processing' do
        expect(updater.instance_variable_get(:@inputs_update)).not_to receive(:process)
        expect(scenario).not_to receive(:save)

        updater.apply
      end
    end

    context 'with only non-input changes' do
      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      it 'still processes inputs' do
        inputs_update = updater.instance_variable_get(:@inputs_update)
        expect(inputs_update).to receive(:process).and_call_original

        updater.apply
      end
    end
  end
end
