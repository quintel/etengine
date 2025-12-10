# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioUpdater::Services::ValidateInputValues, :etsource_fixture do
  let(:scenario) { create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:service) { described_class.new }

  before do
    Rails.cache.clear
  end

  describe '#call' do
    context 'when skip_validation is true' do
      it 'returns Success without validation' do
        result = service.call(scenario, { 'nonexistent_input' => 1 }, true)
        expect(result).to be_success
      end

      it 'does not check input existence' do
        allow(Input).to receive(:get)
        service.call(scenario, { 'some_input' => 1 }, true)
        expect(Input).not_to have_received(:get)
      end

      it 'does not read cache' do
        allow(Input).to receive(:cache)
        service.call(scenario, { 'some_input' => 1 }, true)
        expect(Input).not_to have_received(:cache)
      end
    end

    context 'with valid inputs' do
      let(:user_values) do
        {
          'foo_demand' => 50
        }
      end

      it 'returns Success' do
        result = service.call(scenario, user_values)
        expect(result).to be_success
      end

      it 'fetches input data from cache' do
        allow(Input).to receive(:cache).and_call_original
        service.call(scenario, user_values)
        expect(Input).to have_received(:cache).with(scenario)
      end

      it 'uses read_many for batch fetching' do
        cache = Input.cache(scenario)
        allow(Input).to receive(:cache).with(scenario).and_return(cache)
        allow(cache).to receive(:read_many).and_call_original

        service.call(scenario, user_values)
        expect(cache).to have_received(:read_many)
      end
    end

    context 'with multiple valid inputs' do
      let(:user_values) do
        {
          'foo_demand' => 50,
          'lft_demand' => 25
        }
      end

      it 'returns Success' do
        result = service.call(scenario, user_values)
        expect(result).to be_success
      end

      it 'validates all inputs at once' do
        cache = Input.cache(scenario)
        allow(Input).to receive(:cache).with(scenario).and_return(cache)
        allow(cache).to receive(:read_many).and_call_original

        service.call(scenario, user_values)
        expect(cache).to have_received(:read_many).once
      end
    end

    context 'with nonexistent input' do
      let(:user_values) do
        {
          'nonexistent_input' => 100
        }
      end

      it 'returns Failure' do
        result = service.call(scenario, user_values)
        expect(result).to be_failure
      end

      it 'includes error message' do
        result = service.call(scenario, user_values)
        expect(result.failure.first).to include('nonexistent_input')
      end
    end

    context 'with mix of valid and invalid inputs' do
      let(:user_values) do
        {
          'foo_demand' => 50,
          'nonexistent_input' => 100
        }
      end

      it 'returns Failure' do
        result = service.call(scenario, user_values)
        expect(result).to be_failure
      end

      it 'reports all invalid inputs' do
        result = service.call(scenario, user_values)
        expect(result.failure.join(', ')).to include('nonexistent_input')
      end
    end

    context 'with input resets' do
      let(:user_values) do
        {
          'foo_demand' => 50,
          'lft_demand' => :reset
        }
      end

      it 'returns Success' do
        result = service.call(scenario, user_values)
        expect(result).to be_success
      end

      it 'validates only non-reset inputs' do
        cache = Input.cache(scenario)
        allow(Input).to receive(:cache).with(scenario).and_return(cache)
        allow(cache).to receive(:read_many).and_call_original

        service.call(scenario, user_values)
        expect(cache).to have_received(:read_many).with(
          scenario,
          array_including(instance_of(Input))
        )
      end
    end

    context 'with empty user values' do
      let(:user_values) { {} }

      it 'returns Success' do
        result = service.call(scenario, user_values)
        expect(result).to be_success
      end

      it 'calls read_many with empty array' do
        cache = Input.cache(scenario)
        allow(Input).to receive(:cache).with(scenario).and_return(cache)
        allow(cache).to receive(:read_many).and_call_original
        service.call(scenario, user_values)
        expect(cache).to have_received(:read_many).with(scenario, [])
      end
    end

    context 'with scaled scenario and valid input' do
      before do
        scenario.create_scaler!(
          area_attribute: 'present_number_of_residences',
          value: 500_000
        )
      end

      let(:user_values) do
        {
          'foo_demand' => 1
        }
      end

      it 'returns Success' do
        result = service.call(scenario, user_values)
        expect(result).to be_success
      end

      it 'uses Input::ScaledInputs' do
        cache = Input.cache(scenario)
        expect(cache).to be_a(Input::ScaledInputs)
      end

      it 'calls read_many on ScaledInputs' do
        scaled_cache = Input.cache(scenario)
        allow(scaled_cache).to receive(:read_many).and_call_original

        service.call(scenario, user_values)
        expect(scaled_cache).to have_received(:read_many)
      end
    end

    context 'with scaled scenario and multiple valid inputs' do
      before do
        scenario.create_scaler!(
          area_attribute: 'present_number_of_residences',
          value: 500_000
        )
      end

      let(:user_values) do
        {
          'foo_demand' => 1,
          'lft_demand' => 1
        }
      end

      it 'returns Success' do
        result = service.call(scenario, user_values)
        expect(result).to be_success
      end

      it 'validates all inputs with scaling applied' do
        scaled_cache = Input.cache(scenario)
        allow(scaled_cache).to receive(:read_many).and_call_original

        service.call(scenario, user_values)
        expect(scaled_cache).to have_received(:read_many).once
      end
    end

    context 'with scaled scenario and invalid input' do
      before do
        scenario.create_scaler!(
          area_attribute: 'present_number_of_residences',
          value: 500_000
        )
      end

      let(:user_values) do
        {
          'nonexistent_scaled_input' => 100
        }
      end

      it 'returns Failure' do
        result = service.call(scenario, user_values)
        expect(result).to be_failure
      end
    end
  end
end
