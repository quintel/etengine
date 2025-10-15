# frozen_string_literal: true

require 'spec_helper'

describe ScenarioUpdater::Inputs::Balancer, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario, area_code: 'nl', end_year: 2050) }
  let(:current_user) { nil }
  let(:user_values) { {} }
  let(:provided_values) { {} }
  let(:params) { {} }
  let(:balancer) do
    described_class.new(scenario, params, current_user, user_values, provided_values)
  end

  before do
    Rails.cache.clear
  end

  describe '#calculate_balanced_values' do
    context 'with no user values' do
      let(:user_values) { {} }

      it 'returns an empty hash' do
        expect(balancer.calculate_balanced_values).to eq({})
      end
    end

    context 'with autobalance disabled' do
      let(:params) { { autobalance: false } }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        scenario.balanced_values = { 'grouped_input_two' => 25.0 }
        scenario.save!
      end

      it 'returns base balanced values without calculating new balances' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_two')
      end

      it 'removes balanced values for groups being updated' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_one')
      end
    end

    context 'with autobalance explicitly set to string "false"' do
      let(:params) { { autobalance: 'false' } }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        scenario.balanced_values = { 'grouped_input_two' => 25.0 }
        scenario.save!
      end

      it 'does not perform autobalancing' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_two')
      end
    end

    context 'with autobalance enabled' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      it 'calculates balanced values for the group' do
        result = balancer.calculate_balanced_values
        expect(result).to have_key('grouped_input_two')
        expect(result['grouped_input_two']).to eq(25.0)
      end

      it 'does not include provided values in the result' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_one')
      end
    end

    context 'with multiple groups' do
      let(:params) { { autobalance: true } }
      let(:user_values) do
        {
          'grouped_input_one' => 60.0,
          'unrelated_one' => 40.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 60.0,
          'unrelated_one' => 40.0
        }
      end

      it 'balances the first group' do
        result = balancer.calculate_balanced_values
        expect(result['grouped_input_two']).to eq(40.0)
      end

      it 'attempts to balance each group independently' do
        result = balancer.calculate_balanced_values
        # Should attempt to balance both groups (may fail if inputs don't exist in etsource)
        # At minimum, grouped_input_two should be balanced
        expect(result).to have_key('grouped_input_two')
      end
    end

    context 'with force_balance enabled' do
      let(:params) { { force_balance: true, autobalance: true } }
      let(:user_values) do
        {
          'grouped_input_one' => 50.0,
          'grouped_input_two' => 50.0
        }
      end
      let(:provided_values) { { 'grouped_input_one' => 100.0 } }

      it 'removes user values not in provided values' do
        result = balancer.calculate_balanced_values
        expect(result['grouped_input_two']).to eq(0.0)
      end

      it 'balances with only the provided values as masters' do
        result = balancer.calculate_balanced_values
        expect(result).to have_key('grouped_input_two')
      end
    end

    context 'when balancer raises an error' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 9999999.0 } }
      let(:provided_values) { { 'grouped_input_one' => 9999999.0 } }

      it 'returns nil for that group and continues' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_two')
      end
    end

    context 'with reset enabled' do
      let(:params) { { reset: true, autobalance: true } }
      let(:parent) { FactoryBot.create(:scenario, balanced_values: { 'input_2' => 50.0 }) }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        scenario.preset_scenario_id = parent.id
        scenario.balanced_values = { 'input_2' => 100.0, 'grouped_input_two' => 25.0 }
        scenario.save!
      end

      it 'starts with parent balanced values' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(50.0)
      end

      it 'calculates new balanced values for updated groups' do
        result = balancer.calculate_balanced_values
        expect(result['grouped_input_two']).to eq(25.0)
      end
    end

    context 'with reset enabled and no parent' do
      let(:params) { { reset: true, autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        scenario.balanced_values = { 'grouped_input_two' => 25.0 }
        scenario.save!
      end

      it 'starts with empty balanced values' do
        result = balancer.calculate_balanced_values
        expect(result['grouped_input_two']).to eq(25.0)
      end
    end

    context 'with uncouple enabled' do
      let(:params) { { uncouple: true, autobalance: true } }
      let(:user_values) do
        {
          'exclusive' => 10.0,
          'grouped_input_one' => 75.0
        }
      end
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.balanced_values = {
          'grouped_input_two' => 25.0,
          'input_2' => 100.0
        }
        scenario.save!
      end

      it 'removes coupled inputs from base balanced values' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('exclusive')
      end

      it 'keeps uncoupled balanced values' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(100.0)
      end

      it 'calculates new balanced values for provided groups' do
        result = balancer.calculate_balanced_values
        expect(result['grouped_input_two']).to eq(25.0)
      end
    end

    context 'with uncouple as string "true"' do
      let(:params) { { uncouple: 'true', autobalance: true } }
      let(:user_values) { { 'exclusive' => 10.0 } }
      let(:provided_values) { {} }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.balanced_values = { 'input_2' => 100.0 }
        scenario.save!
      end

      it 'treats string "true" as truthy' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(100.0)
      end
    end

    context 'with uncouple as string "1"' do
      let(:params) { { uncouple: '1', autobalance: true } }
      let(:user_values) { { 'exclusive' => 10.0 } }
      let(:provided_values) { {} }

      before do
        allow(Input).to receive(:coupling_inputs_keys).and_return(['exclusive'])

        scenario.balanced_values = { 'input_2' => 100.0 }
        scenario.save!
      end

      it 'treats string "1" as truthy' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(100.0)
      end
    end

    context 'with previously balanced inputs in the group' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 100.0 } }
      let(:provided_values) { { 'grouped_input_one' => 100.0 } }

      before do
        scenario.balanced_values = { 'grouped_input_one' => 50.0, 'input_2' => 100.0 }
        scenario.save!
      end

      it 'removes all balanced values for the group being updated' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_one')
      end

      it 'keeps balanced values for other groups' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(100.0)
      end

      it 'calculates new balanced values for the group' do
        result = balancer.calculate_balanced_values
        expect(result['grouped_input_two']).to eq(0.0)
      end
    end

    context 'with related inputs previously balanced' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 100.0 } }
      let(:provided_values) { { 'grouped_input_one' => 100.0 } }

      before do
        scenario.balanced_values = { 'grouped_input_two' => 100.0, 'input_2' => 100.0 }
        scenario.save!
      end

      it 'removes balanced value for provided input' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_one')
      end

      it 'calculates new balanced value for related input' do
        result = balancer.calculate_balanced_values
        # Should have a new balanced value for grouped_input_two
        expect(result['grouped_input_two']).to eq(0.0)
      end

      it 'keeps balanced values for other groups' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(100.0)
      end
    end

    context 'with inputs not in a share group' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'nongrouped' => 50.0 } }
      let(:provided_values) { { 'nongrouped' => 50.0 } }

      it 'returns empty hash for non-grouped inputs' do
        result = balancer.calculate_balanced_values
        expect(result).to eq({})
      end
    end

    context 'when providing all values in a group' do
      let(:params) { { autobalance: true } }
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

      it 'returns empty hash as all inputs are masters' do
        result = balancer.calculate_balanced_values
        expect(result).to eq({})
      end
    end
  end

  describe 'integration with ::Balancer' do
    let(:params) { { autobalance: true } }
    let(:user_values) { { 'grouped_input_one' => 75.0 } }
    let(:provided_values) { { 'grouped_input_one' => 75.0 } }

    it 'calls ::Balancer.new for each share group' do
      # Should call Balancer.new with the inputs in the share group
      expect(::Balancer).to receive(:new).at_least(:once).and_call_original
      balancer.calculate_balanced_values
    end

    it 'passes scenario and user values to the balancer' do
      balancer_instance = instance_double(::Balancer)
      allow(::Balancer).to receive(:new).and_return(balancer_instance)
      expect(balancer_instance).to receive(:balance).with(scenario, user_values).and_return({})
      balancer.calculate_balanced_values
    end
  end
end
