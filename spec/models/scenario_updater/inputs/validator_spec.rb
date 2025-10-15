# frozen_string_literal: true

require 'spec_helper'

describe ScenarioUpdater::Inputs::Validator, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:provided_values) { {} }
  let(:current_user) { nil }
  let(:validator) { described_class.new(scenario, provided_values, current_user) }

  before do
    Rails.cache.clear
  end

  shared_examples_for 'a valid validator' do
    it 'is valid' do
      expect(validator).to be_valid
    end

    it 'has no errors' do
      validator.valid?
      expect(validator.errors).to be_blank
    end
  end

  shared_examples_for 'an invalid validator' do |error_message|
    it 'is not valid' do
      expect(validator).not_to be_valid
    end

    it 'has errors' do
      validator.valid?
      expect(validator.errors).not_to be_blank
    end

    if error_message
      it "includes the expected error message" do
        validator.valid?
        expect(validator.errors.full_messages.join(', ')).to include(error_message)
      end
    end
  end

  describe 'with no provided values' do
    let(:provided_values) { {} }

    it_behaves_like 'a valid validator'
  end

  describe 'numeric input validation' do
    context 'with a valid numeric value' do
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      it_behaves_like 'a valid validator'

      it 'does not modify the value' do
        validator.valid?
        expect(provided_values['foo_demand']).to eq(50.0)
      end
    end

    context 'with a value below minimum' do
      let(:provided_values) { { 'foo_demand' => -5.0 } }

      it_behaves_like 'an invalid validator', 'cannot be less than'
    end

    context 'with a value above maximum' do
      let(:provided_values) { { 'foo_demand' => 999999.0 } }

      it_behaves_like 'an invalid validator', 'cannot be greater than'
    end

    context 'with a blank value' do
      let(:provided_values) { { 'foo_demand' => nil } }

      it_behaves_like 'an invalid validator', 'must be numeric'
    end

    context 'with an empty string' do
      let(:provided_values) { { 'foo_demand' => '' } }

      it_behaves_like 'an invalid validator', 'must be numeric'
    end
  end

  describe 'step value coercion' do
    # Note: Using foo_demand for step tests. The actual step value comes from etsource.
    # We're testing that coercion happens when a value doesn't align with the step.

    context 'with a value that needs coercion' do
      let(:provided_values) { { 'foo_demand' => 50.3 } }
      let(:input) { Input.get('foo_demand') }
      let(:input_data) { Input.cache(scenario).read(scenario, input) }

      before do
        # Skip if the input has no step or step is 0
        skip 'foo_demand has no step value' if input_data[:step].nil? || input_data[:step].zero?
      end

      it 'coerces the value to align with the step' do
        validator.valid?

        # Calculate what the coerced value should be
        min = input_data[:min]
        step = input_data[:step]
        steps_from_min = ((50.3 - min) / step).round
        expected = min + (steps_from_min * step)

        expect(provided_values['foo_demand']).to eq(expected)
      end
    end

    context 'with a value that coerces beyond the maximum' do
      let(:input) { Input.get('foo_demand') }
      let(:input_data) { Input.cache(scenario).read(scenario, input) }

      # Use a value just above max that will coerce even higher
      let(:provided_values) do
        max = input_data[:max]
        step = input_data[:step] || 1.0
        { 'foo_demand' => max + (step * 0.6) }
      end

      before do
        skip 'foo_demand has no step value' if input_data[:step].nil? || input_data[:step].zero?
      end

      it_behaves_like 'an invalid validator', 'cannot be greater than'

      it 'coerces the value first, then fails validation' do
        original_value = provided_values['foo_demand']
        validator.valid?
        # Value should have been coerced before validation
        expect(provided_values['foo_demand']).not_to eq(original_value)
      end
    end
  end

  describe 'enum input validation' do
    # Find a real enum input from etsource
    let(:enum_input) { Input.all.find { |i| i.enum? } }
    let(:enum_key) { enum_input&.key }
    let(:permitted_values) do
      enum_input ? Input.cache(scenario).read(scenario, enum_input)[:min] : []
    end

    before do
      skip 'No enum inputs available in etsource' unless enum_input
    end

    context 'with a valid enum value' do
      let(:provided_values) { { enum_key => permitted_values.first } }

      it_behaves_like 'a valid validator'
    end

    context 'with another valid enum value' do
      let(:provided_values) { { enum_key => permitted_values.last } }

      it_behaves_like 'a valid validator'
    end

    context 'with an invalid enum value' do
      let(:provided_values) { { enum_key => 'definitely_invalid_option_12345' } }

      it_behaves_like 'an invalid validator', 'must be one of'

      it 'lists the permitted values in the error' do
        validator.valid?
        error_message = validator.errors.full_messages.first
        expect(error_message).to include('must be one of')
        permitted_values.each do |value|
          stripped_value = value.to_s.gsub(/^"|"$/, '')
          expect(error_message).to include(stripped_value)
        end
      end
    end
  end

  describe 'boolean input validation' do
    # Find a real boolean input from etsource
    let(:bool_input) { Input.all.find { |i| i.unit == 'bool' } }
    let(:bool_key) { bool_input&.key }

    before do
      skip 'No boolean inputs available in etsource' unless bool_input
    end

    context 'with value 0' do
      let(:provided_values) { { bool_key => 0 } }

      it_behaves_like 'a valid validator'
    end

    context 'with value 1' do
      let(:provided_values) { { bool_key => 1 } }

      it_behaves_like 'a valid validator'
    end

    context 'with an invalid value (2)' do
      let(:provided_values) { { bool_key => 2 } }

      it_behaves_like 'an invalid validator', 'must be one 0 or 1'
    end

    context 'with an invalid value (0.5)' do
      let(:provided_values) { { bool_key => 0.5 } }

      it_behaves_like 'an invalid validator', 'must be one 0 or 1'
    end

    context 'with nil' do
      let(:provided_values) { { bool_key => nil } }

      it_behaves_like 'an invalid validator', 'must be one 0 or 1'
    end
  end

  describe 'non-existent input' do
    context 'with a key that does not exist' do
      let(:provided_values) { { 'nonexistent_input' => 50.0 } }

      it_behaves_like 'an invalid validator', 'does not exist'
    end
  end

  describe 'multiple inputs with mixed validity' do
    context 'when all inputs are valid' do
      let(:provided_values) do
        {
          'foo_demand' => 50.0,
          'input_2' => 75.0
        }
      end

      it_behaves_like 'a valid validator'
    end

    context 'when multiple inputs are invalid' do
      let(:provided_values) do
        {
          'foo_demand' => -10.0,  # Below min
          'input_2' => 999999.0    # Above max
        }
      end

      it_behaves_like 'an invalid validator'

      it 'reports all errors' do
        validator.valid?
        expect(validator.errors.count).to eq(2)
      end
    end
  end

  describe 'integration with Input.cache' do
    let(:provided_values) { { 'foo_demand' => 50.0 } }

    it 'uses cached input data from Input.cache' do
      expect(Input).to receive(:cache).with(scenario).and_call_original
      validator.valid?
    end

    it 'reads input data for each provided input' do
      cache = Input.cache(scenario)
      input = Input.get('foo_demand')
      expect(Input).to receive(:cache).with(scenario).and_return(cache)
      expect(cache).to receive(:read).with(scenario, input).and_call_original
      validator.valid?
    end
  end

  describe '#coerce_to_step' do
    # Testing the private method for thoroughness
    let(:validator_instance) { described_class.new(scenario, {}, nil) }

    it 'returns the value unchanged when step is zero' do
      result = validator_instance.send(:coerce_to_step, 23.7, 0, 0)
      expect(result).to eq(23.7)
    end

    it 'returns the value unchanged when step is nil' do
      result = validator_instance.send(:coerce_to_step, 23.7, 0, nil)
      expect(result).to eq(23.7)
    end

    it 'coerces to the correct step value' do
      result = validator_instance.send(:coerce_to_step, 23.7, 0, 5)
      expect(result).to eq(25.0)
    end

    it 'coerces relative to the minimum value' do
      result = validator_instance.send(:coerce_to_step, 21.0, 10, 3)
      expect(result).to eq(22.0)  # 10 + (4 * 3) = 22
    end

    it 'handles negative values' do
      result = validator_instance.send(:coerce_to_step, -7.0, -10, 2)
      expect(result).to eq(-6.0)  # -10 + (2 * 2) = -6
    end

    it 'handles fractional steps' do
      result = validator_instance.send(:coerce_to_step, 7.3, 0, 0.5)
      expect(result).to eq(7.5)
    end
  end
end
