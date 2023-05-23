# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ScenarioUpdater, :etsource_fixture do
  shared_examples_for 'a successful scenario update' do
    it 'is valid' do
      expect(updater).to be_valid
    end

    it 'has no errors' do
      updater.valid?
      expect(updater.errors).to be_blank
    end

    it 'saves the changes' do
      expect(updater.apply).to be_truthy
    end
  end

  shared_examples_for 'a failed scenario update' do
    it 'is not valid' do
      expect(updater).not_to be_valid
    end

    it 'has errors' do
      updater.valid?
      expect(updater.errors).not_to be_blank
    end

    it 'does not save any changes' do
      expect(updater.apply).to be_falsey
    end

    it 'does not change any values' do
      old_attributes = scenario.reload.attributes
        .except('user_values', 'balanced_values')

      user_values     = scenario.user_values
      balanced_values = scenario.balanced_values

      updater.apply
      scenario.reload

      new_attributes = scenario.attributes
        .except('user_values', 'balanced_values')

      expect(new_attributes).to eql(old_attributes)
      expect(scenario.user_values).to eql(user_values)
      expect(scenario.balanced_values).to eql(balanced_values)

      expect(scenario.user_values).not_to be_nil
      expect(scenario.balanced_values).not_to be_nil
    end
  end

  let(:scenario) { FactoryBot.create(:scenario) }
  let(:updater)  { Api::V3::ScenarioUpdater.new(scenario, params) }

  context 'with no user parameters' do
    let(:params) { {} }

    it_behaves_like 'a successful scenario update'

    it 'makes no changes' do
      allow(scenario).to receive(:save)
      updater.apply
      expect(scenario).not_to have_received(:save)
    end
  end

  context 'with parameters, but no user values' do
    before do
      scenario.update!(
        end_year: 2035,
        user_values: { 'foo_demand' => 1.0 }
      )
    end

    let(:params) { { autobalance: true, scenario: { keep_compatible: true } } }

    it_behaves_like 'a successful scenario update'

    it 'saves the scenario attributes' do
      expect { updater.apply }.to change { scenario.reload.keep_compatible? }.from(false).to(true)
    end

    it 'does not change the user values' do
      updater.apply
      expect(scenario.reload.user_values).to eql('foo_demand' => 1.0)
    end
  end

  context 'with a clean scenario' do
    let(:params) do
      {
        scenario: { user_values: { 'foo_demand' => '10.0' } }
      }
    end

    it_behaves_like 'a successful scenario update'

    it 'sets the input values' do
      updater.apply
      scenario.reload

      expect(scenario.user_values).to eql('foo_demand' => 10.0)
    end
  end

  context 'when the scenario has existing values' do
    let(:params) do
      {
        scenario: { user_values: {
          'foo_demand' => '10.0',
          'input_2' => '15.0'
        } }
      }
    end

    before do
      scenario.user_values = { 'foo_demand' => '5.0' }
      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'overwrites older values' do
      updater.apply
      expect(scenario.reload.user_values).to include('foo_demand' => 10.0)
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 15.0)
    end
  end

  context 'when resetting an entire scenario' do
    let(:params) { { reset: true } }

    before do
      scenario.user_values = { 'foo_demand' => '5.0' }
      scenario.balanced_values = { 'input_2' => '5.0' }
      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'removes all input values' do
      updater.apply
      expect(scenario.reload.user_values).to eq({})
    end

    it 'removes all balanced values' do
      updater.apply
      expect(scenario.reload.balanced_values).to eq({})
    end
  end

  context 'when resetting an entire scenario and providing new values' do
    let(:params) do
      {
        reset: true,
        scenario: { user_values: { foo_demand: 1 } }
      }
    end

    before do
      scenario.user_values = {
        'foo_demand' => 5.0,
        'bar_demand' => 25.5
      }

      scenario.balanced_values = { 'input_2' => '5.0' }

      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'sets new values' do
      updater.apply
      expect(scenario.reload.user_values).to include('foo_demand' => 1.0)
    end

    it 'removes unspecified input values' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('bar_demand')
    end

    it 'removes all balanced values' do
      updater.apply
      expect(scenario.reload.balanced_values).to eq({})
    end
  end

  context 'when resetting an entire scenario, while providing new values ' \
          'with a parent' do
    let(:params) do
      {
        reset: true,
        scenario: { user_values: { foo_demand: 1 } }
      }
    end

    let(:parent) do
      FactoryBot.create(:scenario, user_values: {
        foo_demand: 10.0,
        input_2: 100,
        input_3: 125
      })
    end

    before do
      scenario.user_values = {
        'foo_demand' => 5.0,
        'bar_demand' => 25.5
      }

      scenario.balanced_values = { 'input_2' => '5.0' }

      scenario.preset_scenario_id = parent.id
      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'sets new values' do
      updater.apply
      expect(scenario.reload.user_values).to include('foo_demand' => 1.0)
    end

    it 'removes unspecified input values' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('bar_demand')
    end

    it 'removes all balanced values' do
      updater.apply
      expect(scenario.reload.balanced_values).to eq({})
    end

    it 'restores the parents original values' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_3' => 125)
    end
  end

  context 'when uncoupling a scenario that was coupled' do
    let(:params) do
      {
        coupling: false,
        scenario: { user_values: { foo_demand: 1 } }
      }
    end

    before do
      allow(Input).to receive(:coupling_sliders_keys).and_return(['exclusive'])

      scenario.user_values = {
        exclusive: 10.0,
        input_2: 100
      }

      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'removes coupled input values' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('exclusive')
    end

    it 'keeps other input values' do
      updater.apply
      expect(scenario.reload.user_values).to have_key('input_2')
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to have_key('foo_demand')
    end

    it 'shows as not coupled' do
      updater.apply
      expect(scenario.reload.coupled?).to be_falsey
    end
  end

  context 'when uncoupling a scenario that was not coupled' do
    let(:params) do
      {
        coupling: false,
        scenario: { user_values: { foo_demand: 1 } }
      }
    end

    before do
      scenario.user_values = {
        input_2: 100
      }

      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'keeps other input values' do
      updater.apply
      expect(scenario.reload.user_values).to have_key('input_2')
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to have_key('foo_demand')
    end

    it 'shows as not coupled' do
      updater.apply
      expect(scenario.reload.coupled?).to be_falsey
    end
  end

  context 'when resetting and uncoupling a scenario simultaneously' do
    let(:params) do
      {
        coupling: false,
        reset: true
      }
    end

    before do
      scenario.user_values = {
        exclusive: 10.0,
        input_2: 100
      }

      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'removes other input values' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('input_2')
    end

    it 'removes coupled input values' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('exclusive')
    end

    it 'shows as not coupled' do
      updater.apply
      expect(scenario.reload.coupled?).to be_falsey
    end
  end

  context 'when resetting a single value' do
    let(:params) do
      {
        scenario: { user_values: {
          'foo_demand' => 'reset',
          'input_2' => '15.0'
        } }
      }
    end

    before do
      scenario.user_values = { 'foo_demand' => 5.0 }
      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'removes the reset value' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('foo_demand')
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 15.0)
    end
  end

  context 'when resetting a single value' do
    let(:params) do
      {
        scenario: {
          user_values: {
            'foo_demand' => 'reset',
            'input_2' => '15.0'
          }
        }
      }
    end

    let(:parent) do
      FactoryBot.create(:scenario, user_values: { foo_demand: 10.0 })
    end

    before do
      scenario.user_values = { 'foo_demand' => 5.0 }
      scenario.preset_scenario_id = parent.id
      scenario.save!
    end

    it_behaves_like 'a successful scenario update'

    it 'reverts the input value to that of the parent' do
      updater.apply
      expect(scenario.reload.user_values).to include('foo_demand' => 10)
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 15.0)
    end
  end

  context 'when setting invalid scenario values' do
    let(:params) do
      {
        scenario: { area_code: nil, user_values: { 'foo_demand' => '-1.0' } }
      }
    end

    it_behaves_like 'a failed scenario update'

    it 'warns about the invalid value' do
      updater.valid?

      expect(updater.errors[:base]).to \
        include('Input foo_demand cannot be less than 0.0')
    end
  end

  context 'when setting an invalid input value' do
    let(:params) do
      {
        scenario: { user_values: { 'foo_demand' => '-1.0' } }
      }
    end

    it_behaves_like 'a failed scenario update'
  end

  context 'when sending a string value for a numeric input' do
    before do
      scenario.update(user_values: { 'foo_demand' => 2.5 })
    end

    let(:params) do
      { scenario: { user_values: { 'foo_demand' => 'invalid' } } }
    end

    it_behaves_like 'a failed scenario update'

    it 'does not change user_values' do
      expect { updater.apply }
        .not_to change { scenario.reload.user_values['foo_demand'] }.from(2.5)
    end
  end

  context 'when sending a non-hash user_values attribute' do
    before do
      scenario.update!(user_values: { 'foo_demand' => 1.0 })
    end

    let(:params) do
      {
        scenario: { user_values: nil }
      }
    end

    it_behaves_like 'a successful scenario update'

    it 'does not change user_values' do
      updater.apply
      scenario.reload
      expect(scenario.user_values).to eq('foo_demand' => 1.0)
    end
  end

  context 'when changing a scenario which references an old input' do
    before do
      scenario.update!(user_values: { 'removed' => 1.0 })
    end

    let(:params) do
      {
        scenario: { user_values: { 'foo_demand' => '-1.0' } }
      }
    end

    it_behaves_like 'a failed scenario update'

    it 'does not change the user values' do
      updater.apply
      expect(scenario.reload.user_values).to eql('removed' => 1.0)
    end
  end

  context 'when setting an area-disabled input' do
    let(:params) do
      {
        scenario: { user_values: {
          'foo_demand' => '1.0',
          'input_2' => '50.0'
        } }
      }
    end

    before do
      input = Input.get('foo_demand')
      allow(input).to receive(:disabled_in_current_area?).and_return(true)
    end

    it_behaves_like 'a successful scenario update'

    it 'does not set the disabled input' do
      pending 'should not save disabled inputs'
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('foo_demand')
    end

    it 'sets the enabled input' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 50.0)
    end
  end

  context 'when setting an input in a scaled scenario' do
    let(:scenario) do
      ScenarioScaling.create!(
        scenario: super(),
        area_attribute: 'number_of_residences',
        value: 1_000_000
      ).scenario
    end

    context 'when the input value is within the acceptable range' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: {
            # 5.0 is not an acceptable value in a non-scaled scenario (10.0 is
            # the minimum).
            'input_2' => '5.0'
          } }
        }
      end

      it_behaves_like 'a successful scenario update'
    end

    context 'when the input value is not within the acceptable range' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: {
            # 50000 is an acceptable value in a non-scaled scenario.
            'input_2' => '50000'
          } }
        }
      end

      it_behaves_like 'a failed scenario update'
    end
  end

  context 'when updating grouped inputs without the balancer' do
    context 'when the group adds up' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: {
            'grouped_input_one' => '75.0',
            'grouped_input_two' => '25.0'
          } }
        }
      end

      it_behaves_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        expect(scenario.user_values).to include('grouped_input_one' => 75.0)
        expect(scenario.user_values).to include('grouped_input_two' => 25.0)
      end
    end

    context 'when the input has been previously balanced' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: { 'grouped_input_one' => '100.0' } }
        }
      end

      before do
        scenario.balanced_values = {
          'grouped_input_one' => 50.0,
          'input_2' => 100.0
        }
      end

      it_behaves_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        expect(scenario.balanced_values).not_to have_key('grouped_input_one')
        expect(scenario.balanced_values).not_to have_key('grouped_input_two')
        expect(scenario.balanced_values).to     have_key('input_2')
      end
    end

    context 'when related inputs have been previously balanced' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: { 'grouped_input_one' => '100.0' } }
        }
      end

      before do
        scenario.balanced_values = {
          'grouped_input_two' => 100.0,
          'input_2' => 100.0
        }
      end

      it_behaves_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        expect(scenario.balanced_values).not_to have_key('grouped_input_one')
        expect(scenario.balanced_values).not_to have_key('grouped_input_two')
        expect(scenario.balanced_values).to     have_key('input_2')
      end
    end

    context 'when the group does not add up' do
      let(:params) do
        {
          autobalance: false,
          scenario: { user_values: {
            'grouped_input_one' => '75.0',
            'grouped_input_two' => '10.0'
          } }
        }
      end

      it_behaves_like 'a failed scenario update'

      it 'has an error message' do
        updater.apply

        expect(updater.errors[:base]).to be_any do |error|
          error.match(/"grouped" group does not balance/)
        end
      end
    end
  end
  # end: Updating grouped inputs without the balancer

  context 'when updating a grouped input with the balancer' do
    context 'when the values can be balanced' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: { 'grouped_input_one' => '75.0' } }
        }
      end

      it_behaves_like 'a successful scenario update'

      it 'sets the user value' do
        updater.apply
        expect(scenario.reload.user_values).to eql('grouped_input_one' => 75.0)
      end

      it 'sets the balanced value' do
        updater.apply

        expect(scenario.reload.balanced_values)
          .to eql('grouped_input_two' => 25.0)
      end
    end

    context 'when providing all values' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: {
            'grouped_input_one' => '70.0',
            'grouped_input_two' => '30.0'
          } }
        }
      end

      it_behaves_like 'a successful scenario update'

      it 'sets the user value' do
        updater.apply
        scenario.reload

        expect(scenario.user_values).to eql(
          'grouped_input_one' => 70.0,
          'grouped_input_two' => 30.0
        )
      end

      it 'sets no balanced values' do
        updater.apply
        expect(scenario.reload.balanced_values).to be_blank
      end
    end

    context 'when setting a previously balanced value' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: { 'grouped_input_one' => '100.0' } }
        }
      end

      before do
        scenario.balanced_values = { 'grouped_input_one' => '25.0' }
      end

      it_behaves_like 'a successful scenario update'

      it 'sets the user value' do
        updater.apply
        expect(scenario.reload.user_values).to eql('grouped_input_one' => 100.0)
      end

      it 'sets balanced values' do
        updater.apply

        expect(scenario.reload.balanced_values)
          .to eql('grouped_input_two' => 0.0)
      end
    end

    context 'when the values cannot be balanced' do
      let(:params) do
        {
          autobalance: true,
          scenario: { user_values: { 'grouped_input_one' => '9999999.0' } }
        }
      end

      it_behaves_like 'a failed scenario update'
    end
  end
  # end: Updating a grouped input with the balancer
end
