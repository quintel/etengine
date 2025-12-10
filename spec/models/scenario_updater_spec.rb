# frozen_string_literal: true

require 'spec_helper'

describe ScenarioUpdater, :etsource_fixture do
  let(:current_user) { create(:user) }
  let(:scenario) do
    create(:scenario, area_code: 'nl', end_year: 2050, user: current_user)
  end
  let(:params) { {} }
  let(:updater) { described_class.new(scenario, params, current_user) }
  let(:result) { updater.call }

  before do
    Rails.cache.clear
  end

  shared_examples_for 'a successful call' do
    it 'returns Success' do
      expect(result).to be_success
    end

    it 'returns the updated scenario' do
      expect(result.value!).to eq(scenario)
    end

    it 'persists the scenario' do
      result
      expect(scenario.reload).to be_persisted
    end
  end

  shared_examples_for 'a failed call' do
    it 'returns Failure' do
      expect(result).to be_failure
    end

    it 'does not save the scenario' do
      original_updated_at = scenario.updated_at
      result
      expect(scenario.reload.updated_at).to eq(original_updated_at)
    end

    it 'includes error messages' do
      expect(result.failure).not_to be_empty
    end
  end

  describe '#initialization' do
    it 'sets the scenario' do
      expect(updater.scenario).to eq(scenario)
    end

    it 'sets the params' do
      expect(updater.params).to eq(params)
    end

    it 'sets the current_user' do
      expect(updater.current_user).to eq(current_user)
    end

    context 'with a current user' do
      let(:current_user) { create(:user) }
      let(:scenario) { create(:scenario, area_code: 'nl', end_year: 2050) }

      it 'stores the current_user' do
        expect(updater.current_user).to eq(current_user)
      end
    end

    context 'with nil current_user' do
      let(:current_user) { nil }

      it 'accepts nil current_user' do
        expect(updater.current_user).to be_nil
      end
    end
  end

  describe '#call' do
    context 'with empty params' do
      let(:params) { {} }

      it 'returns Success immediately' do
        expect(result).to be_success
      end

      it 'returns the scenario unchanged' do
        expect(result.value!).to eq(scenario)
      end

      it 'does not modify the scenario' do
        original_updated_at = scenario.updated_at
        result
        expect(scenario.reload.updated_at).to eq(original_updated_at)
      end
    end

    context 'with valid input values' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it_behaves_like 'a successful call'

      it 'updates user_values on the scenario' do
        result
        expect(scenario.reload.user_values).to include('foo_demand' => 50.0)
      end

      it 'updates balanced_values on the scenario' do
        result
        expect(scenario.reload.balanced_values).to be_a(Hash)
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

      it_behaves_like 'a successful call'

      it 'updates scenario private flag' do
        result
        expect(scenario.reload.private).to be(true)
      end

      it 'updates scenario keep_compatible flag' do
        result
        expect(scenario.reload.keep_compatible).to be(true)
      end

      it 'updates scenario source' do
        result
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

      it_behaves_like 'a successful call'

      it 'updates both private flag and user_values' do
        result
        scenario.reload
        expect(scenario.private).to be(true)
        expect(scenario.user_values['foo_demand']).to eq(75.0)
      end
    end

    context 'with invalid input values' do
      let(:params) do
        {
          scenario: {
            user_values: { 'nonexistent_input' => '100.0' }
          }
        }
      end

      it_behaves_like 'a failed call'

      it 'includes input errors' do
        expect(result.failure.join(', ')).to include('nonexistent_input')
      end
    end

    context 'with invalid scenario attributes causing save failure' do
      before do
        scenario.area_code = nil
      end

      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it_behaves_like 'a failed call'

      it 'includes scenario validation errors' do
        expect(result.failure).to be_present
      end
    end

    context 'when scenario save fails due to database error' do
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

      it_behaves_like 'a failed call'
    end

    context 'with metadata in params' do
      let(:params) do
        {
          scenario: {
            metadata: { 'custom_key' => 'custom_value' }
          }
        }
      end

      it_behaves_like 'a successful call'

      it 'updates scenario metadata' do
        result
        expect(scenario.reload.metadata).to include('custom_key' => 'custom_value')
      end
    end

    context 'without metadata in params' do
      let(:scenario) do
        create(:scenario, area_code: 'nl', end_year: 2050, user: current_user,
          metadata: { 'existing' => 'data' })
      end

      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      it 'preserves existing metadata' do
        result
        expect(scenario.reload.metadata).to include('existing' => 'data')
      end
    end

    context 'with set_preset_roles: true' do
      let(:params) do
        {
          scenario: {
            set_preset_roles: true
          }
        }
      end

      it 'calls copy_preset_roles on the scenario' do
        allow(scenario).to receive(:copy_preset_roles).and_call_original
        result
        expect(scenario).to have_received(:copy_preset_roles)
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
        allow(scenario).to receive(:copy_preset_roles).and_call_original
        result
        expect(scenario).to have_received(:copy_preset_roles)
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
        allow(scenario).to receive(:copy_preset_roles).and_call_original
        result
        expect(scenario).to have_received(:copy_preset_roles)
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
        allow(scenario).to receive(:copy_preset_roles)
        result
        expect(scenario).not_to have_received(:copy_preset_roles)
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
        allow(scenario).to receive(:copy_preset_roles)
        result
        expect(scenario).not_to have_received(:copy_preset_roles)
      end
    end

    context 'with a scenario_version_tag present' do
      let(:params) do
        {
          scenario: {
            user_values: { 'foo_demand' => '50.0' }
          }
        }
      end

      it 'updates the version tag with current user' do
        version_tag = instance_double(ScenarioVersionTag)
        allow(version_tag).to receive(:update)
        allow(scenario).to receive(:scenario_version_tag).and_return(version_tag)

        result
        expect(version_tag).to have_received(:update).with(user: current_user)
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
        expect { result }.not_to raise_error
      end

      it_behaves_like 'a successful call'
    end

    context 'when params include protected attributes' do
      let(:params) do
        {
          scenario: {
            area_code: 'de',  # filtered
            end_year: 2060,   # filtered
            private: true     # allowed
          }
        }
      end

      it 'does not update area_code' do
        original_area_code = scenario.area_code
        result
        expect(scenario.reload.area_code).to eq(original_area_code)
      end

      it 'does not update end_year' do
        original_end_year = scenario.end_year
        result
        expect(scenario.reload.end_year).to eq(original_end_year)
      end

      it 'updates allowed attributes' do
        result
        expect(scenario.reload.private).to be(true)
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

      it 'processes user_values correctly' do
        result
        expect(scenario.reload.private).to be(true)
      end

      it 'still processes user_values through services' do
        result
        expect(scenario.reload.user_values['foo_demand']).to eq(50.0)
      end
    end
  end

  describe 'complete update workflow' do
    context 'when updating a scenario with multiple changes' do
      let(:params) do
        {
          scenario: {
            private: true,
            keep_compatible: true,
            source: 'testing',
            user_values: {
              'foo_demand' => '60.0',
              'input_2' => '80.0'
            },
            metadata: {
              'source' => 'api',
              'version' => '2.0'
            }
          }
        }
      end

      it 'successfully applies all changes' do
        expect(result).to be_success

        scenario.reload
        expect(scenario.private).to be(true)
        expect(scenario.keep_compatible).to be(true)
        expect(scenario.source).to eq('testing')
        expect(scenario.user_values['foo_demand']).to eq(60.0)
        expect(scenario.user_values['input_2']).to eq(80.0)
        expect(scenario.metadata['source']).to eq('api')
        expect(scenario.metadata['version']).to eq('2.0')
      end
    end

    context 'with partial update and existing values' do
      let(:scenario) do
        create(
          :scenario,
          area_code: 'nl',
          end_year: 2050,
          user: current_user,
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
        result
        scenario.reload

        expect(scenario.private).to be(true)
        expect(scenario.user_values['foo_demand']).to eq(30.0)
        expect(scenario.user_values['input_2']).to eq(90.0)
        expect(scenario.metadata['existing_key']).to eq('existing_value')
      end
    end

    context 'when resetting input values' do
      let(:scenario) do
        create(
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
        result
        expect(scenario.reload.user_values['foo_demand']).to be_nil
      end
    end
  end

  describe 'edge cases' do
    context 'with nil params' do
      let(:updater) { described_class.new(scenario, nil, current_user) }

      it 'raises an error on call' do
        expect { result }.to raise_error(NoMethodError)
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
        expect(result).to be_success
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
        expect(result).to be_success
        expect(scenario.reload.private).to be(true)
      end
    end

    context 'when scenario is not yet persisted' do
      let(:scenario) do
        build(:scenario, area_code: 'nl', end_year: 2050, user: current_user)
      end
      let(:params) do
        {
          scenario: {
            private: true
          }
        }
      end

      it 'saves the new scenario' do
        expect { result }.to change(Scenario, :count).by(1)
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
        scenario.update!(source: 'Updated by another process')
      end

      it 'overwrites with the new values' do
        result
        expect(scenario.reload.private).to be(true)
      end
    end
  end

  describe 'functional pipeline' do
    let(:params) do
      {
        scenario: {
          user_values: { 'foo_demand' => '50.0' }
        }
      }
    end

    it 'returns a Dry::Monads Result' do
      expect(result).to respond_to(:success?)
      expect(result).to respond_to(:failure?)
    end

    it 'validates before processing' do
      # Invalid input should fail early
      invalid_params = { scenario: { user_values: { 'nonexistent' => '100' } } }
      invalid_result = described_class.new(scenario, invalid_params, current_user).call

      expect(invalid_result).to be_failure
    end

    it 'short-circuits on validation failure' do
      invalid_params = { scenario: { user_values: { 'nonexistent' => '100' } } }

      # Should not modify scenario when validation fails
      expect do
        described_class.new(scenario, invalid_params, current_user).call
      end.not_to(change { scenario.reload.updated_at })
    end
  end

  describe 'performance considerations' do
    context 'with empty params' do
      let(:params) { {} }

      it 'short-circuits without processing' do
        # Empty params should return immediately without database operations
        original_updated_at = scenario.updated_at
        result
        expect(scenario.reload.updated_at).to eq(original_updated_at)
      end

      it 'returns Success immediately' do
        expect(result).to be_success
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

      it 'still processes successfully' do
        expect(result).to be_success
        expect(scenario.reload.private).to be(true)
      end
    end
  end

  describe 'scaled scenarios' do
    before do
      scenario.create_scaler!(
        area_attribute: 'present_number_of_residences',
        value: 500_000
      )
      Rails.cache.clear
    end

    context 'with single input update' do
      let(:params) do
        {
          scenario: {
            user_values: {
              'foo_demand' => '5'
            }
          }
        }
      end

      it 'updates the scaled scenario successfully' do
        expect(result).to be_success
      end

      it 'persists the input value' do
        result
        expect(scenario.reload.user_values['foo_demand']).to eq(5.0)
      end

      it 'uses Input::ScaledInputs for validation' do
        cache = Input.cache(scenario)
        expect(cache).to be_a(Input::ScaledInputs)
      end
    end

    context 'with multiple input updates' do
      let(:params) do
        {
          scenario: {
            user_values: {
              'foo_demand' => '5',
              'lft_demand' => '5'
            }
          }
        }
      end

      it 'updates all inputs successfully' do
        expect(result).to be_success
      end

      it 'persists all input values' do
        result
        reloaded = scenario.reload
        expect(reloaded.user_values['foo_demand']).to eq(5.0)
        expect(reloaded.user_values['lft_demand']).to eq(5.0)
      end

      it 'calls read_many on Input::ScaledInputs' do
        scaled_cache = Input.cache(scenario)
        allow(scaled_cache).to receive(:read_many).and_call_original
        allow(Input).to receive(:cache).with(scenario).and_return(scaled_cache)

        result
        expect(scaled_cache).to have_received(:read_many)
      end
    end

    context 'with invalid input values' do
      let(:params) do
        {
          scenario: {
            user_values: {
              'nonexistent_input' => '100'
            }
          }
        }
      end

      it 'returns failure' do
        expect(result).to be_failure
      end

      it 'does not modify the scenario' do
        original_updated_at = scenario.updated_at
        result
        expect(scenario.reload.updated_at).to eq(original_updated_at)
      end
    end

    context 'with balanced groups' do
      let(:params) do
        {
          scenario: {
            user_values: {
              'grouped_input_one' => '50.0',
              'grouped_input_two' => '50.0'
            }
          }
        }
      end

      it 'processes balanced groups with scaled inputs' do
        expect(result).to be_success
      end
    end

    context 'with metadata changes' do
      let(:params) do
        {
          scenario: {
            metadata: {
              'title' => 'Updated Scaled Scenario'
            },
            user_values: {
              'foo_demand' => '5'
            }
          }
        }
      end

      it 'updates both metadata and inputs' do
        expect(result).to be_success
        reloaded = scenario.reload
        expect(reloaded.metadata['title']).to eq('Updated Scaled Scenario')
        expect(reloaded.user_values['foo_demand']).to eq(5.0)
      end
    end
  end
end
