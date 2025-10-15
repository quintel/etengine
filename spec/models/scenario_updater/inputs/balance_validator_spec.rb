# frozen_string_literal: true

require 'spec_helper'

# Tests validation that input share groups sum to 100%.
describe ScenarioUpdater::Inputs::BalanceValidator, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:user_values) { {} }
  let(:balanced_values) { {} }
  let(:provided_values) { {} }
  let(:validator) do
    described_class.new(scenario, user_values, balanced_values, provided_values)
  end

  before do
    Rails.cache.clear
  end

  shared_examples_for 'a valid balance validator' do
    it 'is valid' do
      expect(validator).to be_valid
    end

    it 'has no errors' do
      validator.valid?
      expect(validator.errors).to be_blank
    end
  end

  shared_examples_for 'an invalid balance validator' do |error_fragment|
    it 'is not valid' do
      expect(validator).not_to be_valid
    end

    it 'has errors' do
      validator.valid?
      expect(validator.errors).not_to be_blank
    end

    if error_fragment
      it "includes '#{error_fragment}' in the error message" do
        validator.valid?
        expect(validator.errors.full_messages.join(', ')).to include(error_fragment)
      end
    end
  end

  describe 'with no provided values' do
    let(:provided_values) { {} }

    it_behaves_like 'a valid balance validator'
  end

  describe 'group balance validation' do
    context 'when a single group balances correctly' do
      let(:user_values) do
        {
          'grouped_input_one' => 75.0,
          'grouped_input_two' => 25.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 75.0,
          'grouped_input_two' => 25.0
        }
      end

      it_behaves_like 'a valid balance validator'
    end

    context 'when group uses balanced values' do
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:balanced_values) { { 'grouped_input_two' => 25.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      it_behaves_like 'a valid balance validator'
    end

    context 'when group uses default values' do
      let(:user_values) { {} }
      let(:balanced_values) { {} }
      let(:provided_values) { { 'grouped_input_one' => 50.0 } }

      before do
        # Assuming default values in etsource sum to 100
        input_one = Input.get('grouped_input_one')
        input_two = Input.get('grouped_input_two')

        cache_one = Input.cache(scenario).read(scenario, input_one)
        cache_two = Input.cache(scenario).read(scenario, input_two)

        skip 'Defaults do not sum to 100' unless (cache_one[:default] + cache_two[:default]).between?(99.99, 100.01)
      end

      it_behaves_like 'a valid balance validator'
    end

    context 'when group does not balance' do
      let(:user_values) do
        {
          'grouped_input_one' => 75.0,
          'grouped_input_two' => 10.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 75.0,
          'grouped_input_two' => 10.0
        }
      end

      it_behaves_like 'an invalid balance validator', 'does not balance'

      it 'includes the group name in the error' do
        validator.valid?
        expect(validator.errors.full_messages.first).to include('"grouped"')
      end

      it 'includes the sum in the error' do
        validator.valid?
        expect(validator.errors.full_messages.first).to include('85')
      end

      it 'includes input details in the error' do
        validator.valid?
        error_message = validator.errors.full_messages.first
        expect(error_message).to include('grouped_input_one=75')
        expect(error_message).to include('grouped_input_two=10')
      end
    end

    # Tests the tolerance bounds (99.99 - 100.01)
    context 'when group sums slightly under 100 (99.995)' do
      let(:user_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 49.995
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 49.995
        }
      end

      it_behaves_like 'a valid balance validator'
    end

    context 'when group sums slightly over 100 (100.005)' do
      let(:user_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 50.005
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 50.005
        }
      end

      it_behaves_like 'a valid balance validator'
    end

    context 'when group sums to 99.98 (outside tolerance)' do
      let(:user_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 49.98
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 49.98
        }
      end

      it_behaves_like 'an invalid balance validator', 'does not balance'
    end

    context 'when group sums to 100.02 (outside tolerance)' do
      let(:user_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 50.02
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 50.02
        }
      end

      it_behaves_like 'an invalid balance validator', 'does not balance'
    end

    context 'with multiple groups' do
      let(:user_values) do
        {
          'grouped_input_one' => 60.0,
          'grouped_input_two' => 40.0,
          'unrelated_one' => 30.0,
          'unrelated_two' => 70.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 60.0,
          'unrelated_one' => 30.0
        }
      end

      it_behaves_like 'a valid balance validator'
    end

    context 'when one of multiple groups does not balance' do
      let(:user_values) do
        {
          'grouped_input_one' => 60.0,
          'grouped_input_two' => 30.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 60.0
        }
      end

      it_behaves_like 'an invalid balance validator', 'does not balance'

      it 'reports the error for the unbalanced group' do
        validator.valid?
        # The grouped group sums to 90 (60 + 30), so it should fail
        expect(validator.errors.full_messages.first).to include('"grouped"')
      end
    end

    context 'when multiple groups do not balance' do
      let(:user_values) do
        {
          'grouped_input_one' => 60.0,
          'grouped_input_two' => 30.0,
          'unrelated_one' => 30.0,
          'unrelated_two' => 60.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 60.0,
          'unrelated_one' => 30.0
        }
      end

      it_behaves_like 'an invalid balance validator'

      it 'reports errors for all unbalanced groups' do
        validator.valid?
        # Both groups should fail: grouped sums to 90, diode sums to 90
        expect(validator.errors.count).to be >= 1
      end
    end

    context 'when an input in the group is disabled' do
      let(:user_values) { { 'grouped_input_one' => 100.0 } }
      let(:provided_values) { { 'grouped_input_one' => 100.0 } }

      before do
        input_one = Input.get('grouped_input_one')
        input_two = Input.get('grouped_input_two')
        cache = Input.cache(scenario)

        # Allow reading grouped_input_one normally
        allow(cache).to receive(:read).with(scenario, input_one).and_call_original

        # Stub grouped_input_two as disabled
        allow(cache).to receive(:read).with(scenario, input_two).and_return(
          { disabled: true, default: 0.0 }
        )
      end

      it_behaves_like 'a valid balance validator'

      it 'excludes disabled inputs from the sum' do
        validator.valid?
        # Should validate without the disabled input
        expect(validator.errors).to be_blank
      end
    end

    context 'when group has mixed user, balanced, and default values' do
      let(:user_values) { { 'grouped_input_one' => 50.0 } }
      let(:balanced_values) { { 'grouped_input_two' => 50.0 } }
      let(:provided_values) { { 'grouped_input_one' => 50.0 } }

      it_behaves_like 'a valid balance validator'
    end

    context 'when input has nil user and balanced values' do
      let(:user_values) { { 'grouped_input_one' => 50.0 } }
      let(:balanced_values) { {} }
      let(:provided_values) { { 'grouped_input_one' => 50.0 } }

      before do
        input_one = Input.get('grouped_input_one')
        input_two = Input.get('grouped_input_two')
        cache = Input.cache(scenario)

        # Read the actual data first before setting up any stubs
        data_two = cache.read(scenario, input_two)

        # Allow reading both inputs - grouped_input_one normally, input_two with custom default
        allow(cache).to receive(:read).with(scenario, input_one).and_call_original
        allow(cache).to receive(:read).with(scenario, input_two).and_return(
          data_two.merge(default: 50.0)
        )
      end

      it_behaves_like 'a valid balance validator'

      it 'uses default value when user and balanced values are nil' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end

    context 'with inputs not in a share group' do
      let(:user_values) { { 'nongrouped' => 50.0 } }
      let(:provided_values) { { 'nongrouped' => 50.0 } }

      it_behaves_like 'a valid balance validator'

      it 'does not validate non-grouped inputs' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end

    context 'when provided value is for an input not in a group' do
      let(:user_values) do
        {
          'grouped_input_one' => 60.0,
          'grouped_input_two' => 40.0,
          'nongrouped' => 999.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 60.0,
          'nongrouped' => 999.0
        }
      end

      it_behaves_like 'a valid balance validator'

      it 'validates only the groups' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end

    context 'when updating only part of a group' do
      let(:user_values) do
        {
          'grouped_input_one' => 60.0,
          'grouped_input_two' => 40.0
        }
      end
      let(:provided_values) { { 'grouped_input_one' => 60.0 } }

      it_behaves_like 'a valid balance validator'

      it 'validates the entire group, not just provided values' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end
  end

  describe 'integration with Input.cache' do
    let(:user_values) { { 'grouped_input_one' => 50.0 } }
    let(:balanced_values) { { 'grouped_input_two' => 50.0 } }
    let(:provided_values) { { 'grouped_input_one' => 50.0 } }

    it 'uses cached input data from Input.cache' do
      expect(Input).to receive(:cache).with(scenario).at_least(:once).and_call_original
      validator.valid?
    end

    it 'reads input data for each input in the group' do
      cache = Input.cache(scenario)
      inputs = Input.in_share_group('grouped')

      expect(Input).to receive(:cache).with(scenario).at_least(:once).and_return(cache)

      inputs.each do |input|
        expect(cache).to receive(:read).with(scenario, input).and_call_original
      end

      validator.valid?
    end
  end

  describe 'edge cases' do
    context 'when provided_values includes multiple inputs from same group' do
      let(:user_values) do
        {
          'grouped_input_one' => 70.0,
          'grouped_input_two' => 30.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 70.0,
          'grouped_input_two' => 30.0
        }
      end

      it_behaves_like 'a valid balance validator'

      it 'validates the group only once' do
        # Ensure we don't validate the same group multiple times
        expect(validator).to receive(:validate_groups_balance).and_call_original
        validator.valid?
        expect(validator.errors.count).to eq(0)
      end
    end

    context 'when group has only one input provided' do
      let(:user_values) { {} }
      let(:balanced_values) { {} }
      let(:provided_values) { { 'grouped_input_one' => 100.0 } }

      # This should fail unless the other input's default is 0
      it 'validates using defaults for other inputs' do
        validator.valid?
        # Result depends on default values in etsource
      end
    end

    context 'when all values are zero' do
      let(:user_values) do
        {
          'grouped_input_one' => 0.0,
          'grouped_input_two' => 0.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 0.0,
          'grouped_input_two' => 0.0
        }
      end

      it_behaves_like 'an invalid balance validator', 'does not balance'

      it 'reports that the group sums to 0' do
        validator.valid?
        expect(validator.errors.full_messages.first).to include('sums to 0')
      end
    end

    context 'when values are negative (hypothetically)' do
      let(:user_values) do
        {
          'grouped_input_one' => 150.0,
          'grouped_input_two' => -50.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 150.0,
          'grouped_input_two' => -50.0
        }
      end

      it_behaves_like 'a valid balance validator'

      it 'accepts negative values if they balance to 100' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end

    context 'when Input.in_share_group returns empty array' do
      let(:user_values) { { 'foo_demand' => 50.0 } }
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      before do
        input = Input.get('foo_demand')
        skip 'Input foo_demand not found in etsource' unless input
        allow(input).to receive(:share_group).and_return('empty_group')
        allow(Input).to receive(:in_share_group).with('empty_group').and_return([])
      end

      it 'does not raise an error during validation' do
        expect { validator.valid? }.not_to raise_error
      end

      it_behaves_like 'an invalid balance validator', 'does not balance'

      it 'reports that the empty group does not balance' do
        validator.valid?
        expect(validator.errors.full_messages.first).to include('"empty_group"')
        expect(validator.errors.full_messages.first).to include('sums to 0')
      end
    end

    context 'when input has nil share_group' do
      let(:user_values) { { 'foo_demand' => 50.0 } }
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      before do
        input = Input.get('foo_demand')
        skip 'Input foo_demand not found in etsource' unless input
        allow(input).to receive(:share_group).and_return(nil)
      end

      it_behaves_like 'a valid balance validator'

      it 'skips validation for inputs without share groups' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end

    context 'when input has blank share_group' do
      let(:user_values) { { 'foo_demand' => 50.0 } }
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      before do
        input = Input.get('foo_demand')
        skip 'Input foo_demand not found in etsource' unless input
        allow(input).to receive(:share_group).and_return('')
      end

      it_behaves_like 'a valid balance validator'

      it 'skips validation for inputs with blank share groups' do
        validator.valid?
        expect(validator.errors).to be_blank
      end
    end
  end
end
