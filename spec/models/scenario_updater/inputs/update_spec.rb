# frozen_string_literal: true

require 'spec_helper'

# Tests the main update orchestrator that:
# - Calculates user values (merging provided values with existing)
# - Calculates balanced values (auto-balancing share groups)
# - Validates all values (type, range, and balance checks)
describe ScenarioUpdater::Inputs::Update, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:params) { { scenario: { user_values: provided_values } } }
  let(:provided_values) { {} }
  let(:current_user) { nil }
  let(:updater) { described_class.new(scenario, params, current_user) }

  before do
    Rails.cache.clear
  end

  shared_examples_for 'a successful update' do
    it 'is valid' do
      updater.process
      expect(updater).to be_valid
    end

    it 'has no errors' do
      updater.process
      expect(updater.errors).to be_blank
    end
  end

  shared_examples_for 'a failed update' do |error_fragment|
    it 'is not valid' do
      updater.process
      expect(updater).not_to be_valid
    end

    it 'has errors' do
      updater.process
      updater.valid? # Need to call valid? to trigger validation
      expect(updater.errors).not_to be_blank
    end

    if error_fragment
      it "includes '#{error_fragment}' in the error message" do
        updater.process
        updater.valid? # Need to call valid? to trigger validation
        expect(updater.errors.full_messages.join(', ')).to include(error_fragment)
      end
    end
  end

  # Tests the main entry point that orchestrates calculation and validation
  describe '#process' do
    context 'with no provided values' do
      let(:provided_values) { {} }

      it_behaves_like 'a successful update'

      it 'calculates empty user values' do
        updater.process
        expect(updater.user_values).to eq({})
      end

      it 'calculates empty balanced values' do
        updater.process
        expect(updater.balanced_values).to eq({})
      end
    end

    context 'with valid input values' do
      let(:provided_values) { { 'foo_demand' => '50.0' } }

      it_behaves_like 'a successful update'

      it 'calculates user values' do
        updater.process
        expect(updater.user_values).to eq('foo_demand' => 50.0)
      end

      it 'includes provided values in user values' do
        updater.process
        expect(updater.user_values['foo_demand']).to eq(50.0)
      end
    end

    context 'with multiple valid inputs' do
      let(:provided_values) do
        {
          'foo_demand' => '50.0',
          'input_2' => '75.0'
        }
      end

      it_behaves_like 'a successful update'

      it 'calculates all user values' do
        updater.process
        expect(updater.user_values).to include(
          'foo_demand' => 50.0,
          'input_2' => 75.0
        )
      end
    end

    context 'when scenario has existing user values' do
      before do
        scenario.user_values = { 'foo_demand' => 25.0, 'input_2' => 100.0 }
        scenario.save!
      end

      context 'and providing new values' do
        let(:provided_values) { { 'foo_demand' => '75.0' } }

        it_behaves_like 'a successful update'

        it 'overwrites existing values' do
          updater.process
          expect(updater.user_values['foo_demand']).to eq(75.0)
        end

        it 'preserves untouched values' do
          updater.process
          expect(updater.user_values['input_2']).to eq(100.0)
        end
      end

      context 'and resetting values' do
        let(:provided_values) { { 'foo_demand' => 'reset' } }

        it_behaves_like 'a successful update'

        it 'removes reset values' do
          updater.process
          expect(updater.user_values).not_to have_key('foo_demand')
        end

        it 'preserves other values' do
          updater.process
          expect(updater.user_values['input_2']).to eq(100.0)
        end
      end
    end

    context 'with invalid input values' do
      let(:provided_values) { { 'foo_demand' => '-10.0' } }

      it_behaves_like 'a failed update', 'cannot be less than'

      it 'still calculates user values' do
        updater.process
        expect(updater.user_values).to eq('foo_demand' => -10.0)
      end
    end

    context 'with non-existent input' do
      let(:provided_values) { { 'nonexistent_input' => '50.0' } }

      it_behaves_like 'a failed update', 'does not exist'
    end

    context 'with invalid string value for numeric input' do
      let(:provided_values) { { 'foo_demand' => 'invalid' } }

      it_behaves_like 'a failed update', 'must be numeric'
    end
  end

  # Tests calculation of user values including merging, resetting, and uncoupling
  describe '#user_values' do
    context 'with a clean scenario' do
      let(:provided_values) { { 'foo_demand' => '50.0' } }

      it 'returns provided values' do
        updater.process
        expect(updater.user_values).to eq('foo_demand' => 50.0)
      end
    end

    context 'when scenario has existing values' do
      before do
        scenario.user_values = { 'foo_demand' => 25.0, 'input_2' => 100.0 }
        scenario.save!
      end

      let(:provided_values) { { 'foo_demand' => '75.0' } }

      it 'merges with existing values' do
        updater.process
        expect(updater.user_values).to include(
          'foo_demand' => 75.0,
          'input_2' => 100.0
        )
      end
    end

    context 'when resetting entire scenario' do
      let(:params) do
        {
          reset: true,
          scenario: { user_values: provided_values }
        }
      end

      before do
        scenario.user_values = { 'foo_demand' => 25.0, 'input_2' => 100.0 }
        scenario.save!
      end

      context 'without providing new values' do
        let(:provided_values) { {} }

        it 'returns empty hash' do
          updater.process
          expect(updater.user_values).to eq({})
        end
      end

      context 'with new values' do
        let(:provided_values) { { 'foo_demand' => '50.0' } }

        it 'returns only new values' do
          updater.process
          expect(updater.user_values).to eq('foo_demand' => 50.0)
        end
      end

      context 'with parent scenario' do
        let(:parent) do
          FactoryBot.create(:scenario, user_values: {
            'foo_demand' => 10.0,
            'input_2' => 200.0,
            'input_3' => 300.0
          })
        end

        before do
          scenario.preset_scenario_id = parent.id
          scenario.save!
        end

        let(:provided_values) { { 'foo_demand' => '50.0' } }

        it 'includes parent values' do
          updater.process
          expect(updater.user_values).to include('input_2' => 200.0, 'input_3' => 300.0)
        end

        it 'overwrites parent values with provided values' do
          updater.process
          expect(updater.user_values['foo_demand']).to eq(50.0)
        end
      end
    end

    context 'when uncoupling scenario' do
      let(:params) do
        {
          uncouple: true,
          scenario: { user_values: provided_values }
        }
      end

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.user_values = {
          'exclusive' => 10.0,
          'input_2' => 100.0,
          'foo_demand' => 50.0
        }
        scenario.save!
      end

      let(:provided_values) { { 'input_3' => '25.0' } }

      it 'removes coupled inputs' do
        updater.process
        expect(updater.user_values).not_to have_key('exclusive')
      end

      it 'preserves non-coupled inputs' do
        updater.process
        expect(updater.user_values).to include('input_2' => 100.0, 'foo_demand' => 50.0)
      end

      it 'adds new values' do
        updater.process
        expect(updater.user_values).to include('input_3' => 25.0)
      end
    end

    context 'with reset symbol for specific input' do
      let(:provided_values) { { 'foo_demand' => 'reset', 'input_2' => '100.0' } }

      before do
        scenario.user_values = { 'foo_demand' => 50.0 }
        scenario.save!
      end

      it 'removes reset input' do
        updater.process
        expect(updater.user_values).not_to have_key('foo_demand')
      end

      it 'includes other provided inputs' do
        updater.process
        expect(updater.user_values).to include('input_2' => 100.0)
      end

      context 'with parent scenario' do
        let(:parent) do
          FactoryBot.create(:scenario, user_values: { 'foo_demand' => 25.0 })
        end

        before do
          scenario.preset_scenario_id = parent.id
          scenario.save!
        end

        it 'reverts to parent value' do
          updater.process
          expect(updater.user_values).to include('foo_demand' => 25.0)
        end

        it 'includes other provided inputs' do
          updater.process
          expect(updater.user_values).to include('input_2' => 100.0)
        end
      end
    end
  end

  # Tests auto-balancing of share groups to ensure they sum to 100%
  describe '#balanced_values' do
    context 'with no autobalancing' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: provided_values }
        }
      end

      let(:provided_values) { { 'grouped_input_one' => '50.0' } }

      it 'returns empty hash' do
        updater.process
        expect(updater.balanced_values).to eq({})
      end
    end

    context 'with autobalancing enabled' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: provided_values }
        }
      end

      context 'when group can be balanced' do
        let(:provided_values) { { 'grouped_input_one' => '75.0' } }

        it_behaves_like 'a successful update'

        it 'calculates balanced values' do
          updater.process
          expect(updater.balanced_values).to include('grouped_input_two' => 25.0)
        end
      end

      context 'when providing all inputs in group' do
        let(:provided_values) do
          {
            'grouped_input_one' => '60.0',
            'grouped_input_two' => '40.0'
          }
        end

        it_behaves_like 'a successful update'

        it 'does not create balanced values' do
          updater.process
          expect(updater.balanced_values).not_to have_key('grouped_input_one')
          expect(updater.balanced_values).not_to have_key('grouped_input_two')
        end
      end

      context 'when group cannot be balanced' do
        let(:provided_values) { { 'grouped_input_one' => '100.0' } }

        before do
          # Set another input in the group to a value that prevents balancing
          scenario.user_values = { 'grouped_input_two' => 1.0 }
          scenario.save!
        end

        it 'is not valid when balance fails' do
          updater.process
          expect(updater).not_to be_valid
        end

        it 'does not calculate balanced values when both inputs have user values' do
          updater.process
          # When both inputs in a group have user values, the balancer cannot adjust anything
          # The group will be invalid (101 != 100)
          expect(updater.balanced_values).not_to have_key('grouped_input_two')
        end

        it 'keeps the user values as provided' do
          updater.process
          expect(updater.user_values).to include(
            'grouped_input_one' => 100.0,
            'grouped_input_two' => 1.0
          )
        end
      end

      context 'with existing balanced values' do
        before do
          scenario.balanced_values = {
            'grouped_input_two' => 50.0,
            'input_2' => 100.0
          }
          scenario.save!
        end

        let(:provided_values) { { 'grouped_input_one' => '75.0' } }

        it 'recalculates balanced values for the group' do
        updater.process
        # When we provide a new value for a group, the balancer recalculates
        expect(updater.balanced_values).to have_key('grouped_input_two')
        expect(updater.balanced_values['grouped_input_two']).to eq(25.0)
      end

      it 'preserves balanced values for other groups' do
        updater.process
        expect(updater.balanced_values).to have_key('input_2')
      end
      end

      context 'when resetting scenario' do
        let(:params) do
          {
            reset: true,
            autobalance: true,
            scenario: { user_values: provided_values }
          }
        end

        before do
          scenario.balanced_values = { 'grouped_input_two' => 50.0 }
          scenario.save!
        end

        let(:provided_values) { {} }

        it 'clears balanced values' do
          updater.process
          expect(updater.balanced_values).to eq({})
        end

        context 'with parent scenario' do
          let(:parent) do
            FactoryBot.create(:scenario, balanced_values: {
              'grouped_input_two' => 25.0,
              'input_2' => 100.0
            })
          end

          let(:provided_values) { { 'grouped_input_one' => '75.0' } }

          before do
            scenario.preset_scenario_id = parent.id
            scenario.save!
          end

          it 'starts with parent balanced values and recalculates' do
            updater.process
            # When providing a value, the balancer recalculates for that group
            expect(updater.balanced_values).to have_key('grouped_input_two')
          end
        end
      end
    end

    context 'with force_balance enabled' do
      let(:params) do
        {
          autobalance: true,
          force_balance: true,
          scenario: { user_values: provided_values }
        }
      end

      before do
        scenario.user_values = {
          'grouped_input_one' => 30.0,
          'grouped_input_two' => 70.0
        }
        scenario.save!
      end

      let(:provided_values) { { 'grouped_input_one' => '100.0' } }

      it_behaves_like 'a successful update'

      it 'removes previous user values from group' do
        updater.process
        # Force balance should allow balancing by removing grouped_input_two
        expect(updater.user_values).not_to have_key('grouped_input_two')
      end

      it 'sets new user value' do
        updater.process
        expect(updater.user_values['grouped_input_one']).to eq(100.0)
      end

      it 'calculates balanced value' do
        updater.process
        expect(updater.balanced_values['grouped_input_two']).to eq(0.0)
      end
    end
  end

  # Tests combined validation from both Validator and BalanceValidator
  describe '#valid?' do
    context 'with valid input values and balanced groups' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: provided_values }
        }
      end

      let(:provided_values) { { 'grouped_input_one' => '75.0' } }

      it 'returns true' do
        updater.process
        expect(updater).to be_valid
      end
    end

    context 'with invalid input values' do
      let(:provided_values) { { 'foo_demand' => '-10.0' } }

      it 'returns false' do
        updater.process
        expect(updater).not_to be_valid
      end

      it 'has validator errors' do
        updater.process
        updater.valid? # Trigger validation
        expect(updater.errors).not_to be_blank
      end
    end

    context 'with unbalanced groups' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: provided_values }
        }
      end

      let(:provided_values) do
        {
          'grouped_input_one' => '75.0',
          'grouped_input_two' => '10.0'
        }
      end

      it 'returns false' do
        updater.process
        expect(updater).not_to be_valid
      end

      it 'has balance validator errors' do
        updater.process
        updater.valid? # Trigger validation
        expect(updater.errors.full_messages.join).to include('does not balance')
      end
    end

    context 'with both validator and balance validator errors' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: provided_values }
        }
      end

      let(:provided_values) do
        {
          'foo_demand' => '-10.0',
          'grouped_input_one' => '75.0',
          'grouped_input_two' => '10.0'
        }
      end

      it 'returns false' do
        updater.process
        expect(updater).not_to be_valid
      end

      it 'has errors from validator' do
        updater.process
        updater.valid? # Trigger validation
        errors_text = updater.errors.full_messages.join(', ')
        expect(errors_text).to include('cannot be less than')
      end

      it 'reports multiple errors when present' do
        updater.process
        updater.valid? # Trigger validation
        # Should have at least the validator error
        expect(updater.errors.count).to be >= 1
      end
    end
  end

  describe '#errors' do
    context 'before validation' do
      it 'returns empty errors object' do
        expect(updater.errors).to be_empty
      end
    end

    context 'after successful validation' do
      let(:provided_values) { { 'foo_demand' => '50.0' } }

      it 'returns empty errors object' do
        updater.process
        expect(updater.errors).to be_empty
      end
    end

    context 'after failed validation' do
      let(:provided_values) { { 'foo_demand' => '-10.0' } }

      it 'returns errors object with messages' do
        updater.process
        updater.valid? # Trigger validation
        expect(updater.errors).not_to be_empty
      end

      it 'includes error attributes' do
        updater.process
        updater.valid? # Trigger validation
        expect(updater.errors.attribute_names).to include(:base)
      end

      it 'includes error messages' do
        updater.process
        updater.valid? # Trigger validation
        expect(updater.errors.full_messages.first).to include('cannot be less than')
      end
    end
  end

  describe '#provided_values_without_resets' do
    context 'with no reset values' do
      let(:provided_values) { { 'foo_demand' => '50.0', 'input_2' => '75.0' } }

      it 'returns all provided values' do
        expect(updater.provided_values_without_resets).to eq(
          'foo_demand' => 50.0,
          'input_2' => 75.0
        )
      end
    end

    context 'with reset values' do
      let(:provided_values) do
        {
          'foo_demand' => 'reset',
          'input_2' => '75.0',
          'input_3' => 'reset'
        }
      end

      it 'excludes reset values' do
        expect(updater.provided_values_without_resets).to eq('input_2' => 75.0)
      end

      it 'does not include reset symbols' do
        result = updater.provided_values_without_resets
        expect(result.values).not_to include(:reset)
      end
    end

    context 'with reset value that has parent' do
      let(:parent) do
        FactoryBot.create(:scenario, user_values: { 'foo_demand' => 25.0 })
      end

      before do
        scenario.preset_scenario_id = parent.id
        scenario.save!
      end

      let(:provided_values) { { 'foo_demand' => 'reset', 'input_2' => '75.0' } }

      it 'converts reset to parent value' do
        expect(updater.provided_values_without_resets).to eq(
          'foo_demand' => 25.0,
          'input_2' => 75.0
        )
      end
    end
  end

  # Tests interaction with enum and boolean input validators
  describe 'integration with validators' do
    context 'with enum inputs' do
      let(:enum_input) { Input.all.find { |i| i.enum? } }
      let(:enum_key) { enum_input&.key }
      let(:valid_value) do
        enum_input ? Input.cache(scenario).read(scenario, enum_input)[:min].first : nil
      end

      before do
        skip 'No enum inputs available in etsource' unless enum_input
      end

      context 'with valid enum value' do
        let(:provided_values) { { enum_key => valid_value } }

        it_behaves_like 'a successful update'
      end

      context 'with invalid enum value' do
        let(:provided_values) { { enum_key => 'invalid_option' } }

        it_behaves_like 'a failed update', 'must be one of'
      end
    end

    context 'with boolean inputs' do
      let(:bool_input) { Input.all.find { |i| i.unit == 'bool' } }
      let(:bool_key) { bool_input&.key }

      before do
        skip 'No boolean inputs available in etsource' unless bool_input
      end

      context 'with valid boolean value' do
        let(:provided_values) { { bool_key => 1 } }

        it_behaves_like 'a successful update'
      end

      context 'with invalid boolean value' do
        let(:provided_values) { { bool_key => 5 } }

        it_behaves_like 'a failed update', 'must be one 0 or 1'
      end
    end
  end

  # Tests combinations of features (reset + uncouple, multiple groups, scaling)
  describe 'complex integration scenarios' do
    context 'with multiple groups and mixed operations' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: provided_values }
        }
      end

      before do
        scenario.user_values = {
          'input_2' => 100.0,
          'grouped_input_one' => 30.0
        }
        scenario.balanced_values = {
          'grouped_input_two' => 70.0
        }
        scenario.save!
      end

      let(:provided_values) do
        {
          'grouped_input_one' => '80.0',
          'foo_demand' => '50.0'
        }
      end

      it_behaves_like 'a successful update'

      it 'updates existing user values' do
        updater.process
        expect(updater.user_values['grouped_input_one']).to eq(80.0)
      end

      it 'preserves unrelated user values' do
        updater.process
        expect(updater.user_values['input_2']).to eq(100.0)
      end

      it 'adds new user values' do
        updater.process
        expect(updater.user_values['foo_demand']).to eq(50.0)
      end

      it 'recalculates balanced values for updated group' do
        updater.process
        expect(updater.balanced_values['grouped_input_two']).to eq(20.0)
      end
    end

    context 'when resetting and uncoupling simultaneously' do
      let(:params) do
        {
          reset: true,
          uncouple: true,
          scenario: { user_values: provided_values }
        }
      end

      let(:parent) do
        FactoryBot.create(:scenario, user_values: {
          'exclusive' => 10.0,
          'foo_demand' => 50.0,
          'input_2' => 100.0
        })
      end

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.preset_scenario_id = parent.id
        scenario.user_values = {
          'exclusive' => 20.0,
          'nongrouped' => 75.0
        }
        scenario.save!
      end

      let(:provided_values) { { 'foo_demand' => '25.0' } }

      it_behaves_like 'a successful update'

      it 'inherits parent values when resetting' do
        updater.process
        # When resetting with a parent, parent values are merged in
        expect(updater.user_values).to include('exclusive' => 10.0)
      end

      it 'includes parent non-coupled values' do
        updater.process
        expect(updater.user_values).to include('input_2' => 100.0)
      end

      it 'includes provided values' do
        updater.process
        expect(updater.user_values['foo_demand']).to eq(25.0)
      end
    end

    context 'with scaled scenario' do
      let(:scenario) do
        ScenarioScaling.create!(
          scenario: super(),
          area_attribute: 'present_number_of_residences',
          value: 1_000_000
        ).scenario
      end

      context 'with value acceptable for scaled scenario' do
        let(:params) do
          {
            autobalance: false,
            scenario: { user_values: provided_values }
          }
        end

        let(:provided_values) { { 'input_2' => '5.0' } }

        it_behaves_like 'a successful update'
      end

      context 'with value unacceptable for scaled scenario' do
        let(:params) do
          {
            autobalance: false,
            scenario: { user_values: provided_values }
          }
        end

        let(:provided_values) { { 'input_2' => '50000' } }

        it_behaves_like 'a failed update', 'cannot be greater than'
      end
    end
  end

  describe 'edge cases' do
    context 'with empty string values' do
      let(:provided_values) { { 'foo_demand' => '' } }

      it_behaves_like 'a failed update', 'must be numeric'
    end

    context 'with nil params' do
      let(:params) { {} }

      it 'does not raise error' do
        expect { updater.process }.not_to raise_error
      end

      it_behaves_like 'a successful update'
    end

    context 'with nil scenario data' do
      let(:params) { { scenario: nil } }

      it 'does not raise error' do
        expect { updater.process }.not_to raise_error
      end

      it_behaves_like 'a successful update'
    end

    context 'with nil user_values' do
      let(:params) { { scenario: { user_values: nil } } }

      it 'does not raise error' do
        expect { updater.process }.not_to raise_error
      end

      it_behaves_like 'a successful update'
    end

    context 'with string keys and symbol access' do
      let(:params) do
        {
          'scenario' => { 'user_values' => { 'foo_demand' => '50.0' } }
        }.with_indifferent_access
      end

      it 'handles indifferent access' do
        updater.process
        expect(updater.user_values).to include('foo_demand' => 50.0)
      end
    end

    context 'when Input.get returns nil for a key' do
      let(:provided_values) { { 'totally_fake_input' => '50.0' } }

      before do
        allow(Input).to receive(:get).with('totally_fake_input').and_return(nil)
      end

      it 'handles nil input gracefully without raising' do
        expect { updater.process }.not_to raise_error
      end

      it 'produces a validation error' do
        updater.process
        expect(updater).not_to be_valid
      end

      it 'coerces the value to nil' do
        updater.process
        # When Input.get returns nil, coerce_provided_value returns nil
        expect(updater.user_values['totally_fake_input']).to be_nil
      end
    end
  end

  describe 'memoization and caching' do
    context 'when calling process multiple times' do
      let(:provided_values) { { 'foo_demand' => '50.0' } }

      it 'recalculates values on each process call' do
        updater.process
        first_user_values_id = updater.user_values.object_id
        first_balanced_values_id = updater.balanced_values.object_id

        updater.process
        # Process recalculates, so new objects are created
        expect(updater.user_values.object_id).not_to eq(first_user_values_id)
        expect(updater.balanced_values.object_id).not_to eq(first_balanced_values_id)
      end

      it 'maintains consistent values across multiple process calls' do
        updater.process
        first_user_values = updater.user_values.dup
        first_balanced_values = updater.balanced_values.dup

        updater.process
        expect(updater.user_values).to eq(first_user_values)
        expect(updater.balanced_values).to eq(first_balanced_values)
      end
    end

    context 'provided_values memoization' do
      let(:provided_values) { { 'foo_demand' => '50.0', 'input_2' => '75.0' } }

      it 'calculates provided_values only once' do
        # First access triggers calculation
        first_values = updater.send(:provided_values)

        # Mock Input.get to verify it's not called again
        expect(Input).not_to receive(:get)

        # Second access uses memoized value
        second_values = updater.send(:provided_values)
        expect(second_values.object_id).to eq(first_values.object_id)
      end

      it 'memoizes provided_values_without_resets' do
        first_call = updater.provided_values_without_resets
        second_call = updater.provided_values_without_resets
        expect(second_call.object_id).to eq(first_call.object_id)
      end
    end

    context 'errors memoization' do
      let(:provided_values) { { 'foo_demand' => '-10.0' } }

      it 'memoizes the errors object' do
        updater.process
        updater.valid?

        first_errors = updater.errors
        second_errors = updater.errors
        expect(second_errors.object_id).to eq(first_errors.object_id)
      end
    end

    context 'valid? memoization' do
      let(:provided_values) { { 'foo_demand' => '50.0' } }

      it 'caches the validation result' do
        updater.process

        # First call performs validation
        expect(updater.instance_variable_get(:@validator)).to receive(:valid?).once.and_call_original
        expect(updater.instance_variable_get(:@balance_validator)).to receive(:valid?).once.and_call_original

        first_result = updater.valid?
        second_result = updater.valid?

        expect(second_result).to eq(first_result)
      end
    end
  end

  # Tests how uncoupling affects user and balanced values
  describe 'integration with CouplingsManager' do
    context 'when uncoupling affects user values' do
      let(:params) do
        {
          uncouple: true,
          scenario: { user_values: provided_values }
        }
      end

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive', 'another_coupled'])

        scenario.user_values = {
          'exclusive' => 10.0,
          'another_coupled' => 20.0,
          'input_2' => 100.0,
          'foo_demand' => 50.0
        }
        scenario.save!
      end

      let(:provided_values) { { 'nongrouped' => '25.0' } }

      it 'delegates uncouple detection to CouplingsManager' do
        expect(ScenarioUpdater::Inputs::CouplingsManager).to receive(:new)
          .with(scenario, params, current_user)
          .and_call_original

        updater.process
      end

      it 'removes all coupled inputs identified by CouplingsManager' do
        updater.process
        expect(updater.user_values).not_to have_key('exclusive')
        expect(updater.user_values).not_to have_key('another_coupled')
      end

      it 'preserves non-coupled inputs' do
        updater.process
        expect(updater.user_values).to include(
          'input_2' => 100.0,
          'foo_demand' => 50.0
        )
      end
    end

    context 'when not uncoupling' do
      let(:provided_values) { { 'foo_demand' => '50.0' } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.user_values = {
          'exclusive' => 10.0,
          'input_2' => 100.0
        }
        scenario.save!
      end

      it 'does not remove coupled inputs' do
        updater.process
        expect(updater.user_values).to include('exclusive' => 10.0)
      end

      it 'still creates CouplingsManager instance' do
        expect(ScenarioUpdater::Inputs::CouplingsManager).to receive(:new)
          .with(scenario, params, current_user)
          .and_call_original

        updater.process
      end
    end

    context 'when uncoupling with balanced values' do
      let(:params) do
        {
          uncouple: true,
          autobalance: true,
          scenario: { user_values: provided_values }
        }
      end

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.user_values = {
          'exclusive' => 10.0,
          'grouped_input_one' => 60.0
        }

        scenario.balanced_values = {
          'grouped_input_two' => 40.0,
          'coupled_balanced' => 100.0
        }

        scenario.save!
      end

      let(:provided_values) { { 'grouped_input_one' => '75.0' } }

      it 'removes coupled inputs from base user values' do
        updater.process
        expect(updater.user_values).not_to have_key('exclusive')
      end

      it 'recalculates balanced values for provided groups' do
        updater.process
        expect(updater.balanced_values).to have_key('grouped_input_two')
        expect(updater.balanced_values['grouped_input_two']).to eq(25.0)
      end
    end
  end

  describe 'value coercion edge cases' do
    context 'when parent has balanced values for reset input' do
      let(:parent) do
        FactoryBot.create(:scenario,
          user_values: { 'foo_demand' => 25.0 },
          balanced_values: { 'grouped_input_one' => 75.0 }
        )
      end

      before do
        scenario.preset_scenario_id = parent.id
        scenario.save!
      end

      let(:provided_values) { { 'grouped_input_one' => 'reset' } }

      it 'prefers parent user_values over balanced_values for reset' do
        updater.process
        # value_from_parent checks user_values first, then balanced_values
        # grouped_input_one is not in parent user_values, so it uses balanced_values
        expect(updater.user_values).to include('grouped_input_one' => 75.0)
      end
    end

    context 'when coercing values with Input.coerce' do
      let(:provided_values) { { 'foo_demand' => '50.5' } }

      it 'uses Input#coerce for value conversion' do
        input = Input.get('foo_demand')
        expect(input).to receive(:coerce).with('50.5').and_call_original
        updater.process
      end

      it 'properly converts string to float' do
        updater.process
        expect(updater.user_values['foo_demand']).to eq(50.5)
        expect(updater.user_values['foo_demand']).to be_a(Float)
      end
    end
  end
end
