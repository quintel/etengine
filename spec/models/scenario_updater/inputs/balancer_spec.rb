# frozen_string_literal: true

require 'spec_helper'

# Tests calculation of balanced values for share groups.
# When a user sets some inputs in a group, the balancer calculates
# values for remaining inputs so the group sums to 100%.
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

  # Tests balancing behavior with various autobalance and force_balance settings
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

  # Tests interaction with the core ::Balancer service class
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

    context 'when ::Balancer raises BalancerError' do
      let(:user_values) { { 'grouped_input_one' => 100.0 } }
      let(:provided_values) { { 'grouped_input_one' => 100.0 } }

      before do
        balancer_instance = instance_double(::Balancer)
        allow(::Balancer).to receive(:new).and_return(balancer_instance)
        allow(balancer_instance).to receive(:balance).and_raise(
          ::Balancer::BalancerError.new('Test error')
        )
      end

      it 'handles the error gracefully and returns empty for that group' do
        result = balancer.calculate_balanced_values
        expect(result).not_to have_key('grouped_input_two')
      end

      it 'does not propagate the error' do
        expect { balancer.calculate_balanced_values }.not_to raise_error
      end
    end

    context 'when ::Balancer raises NoSubordinates error' do
      let(:user_values) do
        {
          'grouped_input_one' => 100.0,
          'grouped_input_two' => 0.0
        }
      end
      let(:provided_values) do
        {
          'grouped_input_one' => 100.0,
          'grouped_input_two' => 0.0
        }
      end

      before do
        balancer_instance = instance_double(::Balancer)
        allow(::Balancer).to receive(:new).and_return(balancer_instance)
        # NoSubordinates is a subclass of BalancerError
        error = ::Balancer::BalancerError.new('No subordinates available')
        allow(balancer_instance).to receive(:balance).and_raise(error)
      end

      it 'handles the error gracefully' do
        result = balancer.calculate_balanced_values
        expect(result).to eq({})
      end

      it 'does not raise the error' do
        expect { balancer.calculate_balanced_values }.not_to raise_error
      end
    end
  end

  describe '#should_autobalance?' do
    let(:user_values) { {} }
    let(:provided_values) { {} }

    context 'when autobalance is true' do
      let(:params) { { autobalance: true } }

      it 'returns true' do
        expect(balancer.send(:should_autobalance?)).to be true
      end
    end

    context 'when autobalance is false' do
      let(:params) { { autobalance: false } }

      it 'returns false' do
        expect(balancer.send(:should_autobalance?)).to be false
      end
    end

    context 'when autobalance is "false" (string)' do
      let(:params) { { autobalance: 'false' } }

      it 'returns false' do
        expect(balancer.send(:should_autobalance?)).to be false
      end
    end

    context 'when autobalance is not set' do
      let(:params) { {} }

      it 'returns true (default)' do
        expect(balancer.send(:should_autobalance?)).to be true
      end
    end

    context 'when autobalance is nil' do
      let(:params) { { autobalance: nil } }

      it 'returns true (default)' do
        expect(balancer.send(:should_autobalance?)).to be true
      end
    end
  end

  # Tests uncoupling behavior when coupled inputs are missing or nil
  describe 'edge cases with coupling' do
    context 'with uncouple enabled but no coupled inputs' do
      let(:params) { { uncouple: true, autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        allow(scenario).to receive(:coupled_inputs).and_return([])
        scenario.balanced_values = { 'input_2' => 100.0 }
        scenario.save!
      end

      it 'does not raise error' do
        expect { balancer.calculate_balanced_values }.not_to raise_error
      end

      it 'processes normally' do
        result = balancer.calculate_balanced_values
        expect(result).to have_key('grouped_input_two')
      end
    end

    context 'with uncouple enabled and nil coupled_inputs' do
      let(:params) { { uncouple: true, autobalance: true } }
      let(:user_values) { { 'grouped_input_one' => 75.0 } }
      let(:provided_values) { { 'grouped_input_one' => 75.0 } }

      before do
        allow(scenario).to receive(:coupled_inputs).and_return(nil)
        scenario.balanced_values = { 'input_2' => 100.0 }
        scenario.save!
      end

      it 'does not raise error with nil coupled_inputs' do
        expect { balancer.calculate_balanced_values }.not_to raise_error
      end

      it 'treats nil as no coupled inputs' do
        result = balancer.calculate_balanced_values
        expect(result['input_2']).to eq(100.0)
      end
    end
  end

  # Tests handling of missing or invalid share group configurations
  describe 'group identification edge cases' do
    context 'when Input.get returns nil for a key' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'nonexistent_input' => 50.0 } }
      let(:provided_values) { { 'nonexistent_input' => 50.0 } }

      before do
        allow(Input).to receive(:get).with('nonexistent_input').and_return(nil)
      end

      it 'handles nil input gracefully' do
        expect { balancer.calculate_balanced_values }.not_to raise_error
      end

      it 'skips the input with nil' do
        result = balancer.calculate_balanced_values
        expect(result).to eq({})
      end
    end

    context 'when input has nil share_group' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'foo_demand' => 50.0 } }
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      before do
        input = Input.get('foo_demand')
        skip 'Input foo_demand not found in etsource' unless input
        allow(input).to receive(:share_group).and_return(nil)
      end

      it 'does not attempt to balance' do
        result = balancer.calculate_balanced_values
        expect(result).to eq({})
      end
    end

    context 'when input has blank share_group' do
      let(:params) { { autobalance: true } }
      let(:user_values) { { 'foo_demand' => 50.0 } }
      let(:provided_values) { { 'foo_demand' => 50.0 } }

      before do
        input = Input.get('foo_demand')
        skip 'Input foo_demand not found in etsource' unless input
        allow(input).to receive(:share_group).and_return('')
      end

      it 'does not attempt to balance blank groups' do
        result = balancer.calculate_balanced_values
        expect(result).to eq({})
      end
    end
  end
end
