require 'spec_helper'

describe Api::V3::ScenarioUpdater, :etsource_fixture do

  shared_examples_for 'a successful scenario update' do
    it 'is valid' do
      expect(updater).to be_valid
      expect(updater.errors).to be_blank
    end

    it 'saves the changes' do
      expect(updater.apply).to be_truthy
    end
  end

  shared_examples_for 'a failed scenario update' do
    it 'is not valid' do
      expect(updater).not_to be_valid
      expect(updater.errors).not_to be_blank
    end

    it 'does not save any changes' do
      expect(updater.apply).to be_falsey
    end

    it 'does not change any values' do
      old_attributes = scenario.reload.attributes.
        except('user_values', 'balanced_values')

      user_values     = scenario.user_values
      balanced_values = scenario.balanced_values

      updater.apply
      scenario.reload

      new_attributes = scenario.attributes.
        except('user_values', 'balanced_values')

      expect(new_attributes).to eql(old_attributes)
      expect(scenario.user_values).to eql(user_values)
      expect(scenario.balanced_values).to eql(balanced_values)

      expect(scenario.user_values).not_to be_nil
      expect(scenario.balanced_values).not_to be_nil
    end
  end

  # --------------------------------------------------------------------------

  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:updater)  { Api::V3::ScenarioUpdater.new(scenario, params) }

  # --------------------------------------------------------------------------

  context 'With no user parameters' do
    let(:params) { Hash.new }

    it_should_behave_like 'a successful scenario update'

    it 'makes no changes' do
      expect(scenario).not_to receive(:save)
      updater.apply
    end
  end # With no user parameters

  # --------------------------------------------------------------------------

  context 'With parameters, but no user values' do
    before do
      scenario.update_attributes!(
        use_fce: true,
        user_values: { 'foo_demand' => 1.0 })
    end

    let(:params) { { autobalance: true, scenario: { use_fce: false } } }

    it_should_behave_like 'a successful scenario update'

    it 'saves the scenario attributes' do
      expect(scenario).to receive(:save)
      updater.apply
      expect(scenario.reload.use_fce).to be_truthy
    end

    it 'does not change the user values' do
      updater.apply
      expect(scenario.reload.user_values).to eql({ 'foo_demand' => 1.0 })
    end
  end # With parameters, but no user values

  # --------------------------------------------------------------------------

  context 'With a clean scenario' do
    let(:params) { {
      scenario: { user_values: { 'foo_demand' => '10.0' } }
    } }

    it_should_behave_like 'a successful scenario update'

    it 'sets the input values' do
      updater.apply
      scenario.reload

      expect(scenario.user_values).to eql({ 'foo_demand' => 10.0 })
    end
  end # With a clean scenario

  # --------------------------------------------------------------------------

  context 'When the scenario has existing values' do
    let(:params) { {
      scenario: { user_values: {
        'foo_demand' => '10.0',
        'input_2'    => '15.0'
      } }
    } }

    before do
      scenario.user_values = { 'foo_demand' => '5.0' }
      scenario.save!
    end

    it_should_behave_like 'a successful scenario update'

    it 'overwrites older values' do
      updater.apply
      expect(scenario.reload.user_values).to include('foo_demand' => 10.0)
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 15.0)
    end
  end # When the scenario has existing values

  # --------------------------------------------------------------------------

  context 'Resetting an entire scenario' do
    let(:params) { { reset: true } }

    before do
      scenario.user_values = { 'foo_demand' => '5.0' }
      scenario.balanced_values = { 'input_2' => '5.0' }
      scenario.save!
    end

    it_should_behave_like 'a successful scenario update'

    it 'removes all input values' do
      updater.apply
      expect(scenario.reload.user_values).to eq({})
    end

    it 'removes all balanced values' do
      updater.apply
      expect(scenario.reload.balanced_values).to eq({})
    end
  end # Resetting an entire scenario

  # --------------------------------------------------------------------------

  context 'Resetting an entire scenario, while providing new values' do
    let(:params) { {
      reset: true,
      scenario: { user_values: { foo_demand: 1 } }
    } }

    before do
      scenario.user_values = {
        'foo_demand' => 5.0,
        'bar_demand' => 25.5
      }

      scenario.balanced_values = { 'input_2' => '5.0' }

      scenario.save!
    end

    it_should_behave_like 'a successful scenario update'

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
  end # Resetting an entire scenario, while providing new values

  # --------------------------------------------------------------------------

  context 'Resetting a single value' do
    let(:params) { {
      scenario: { user_values: {
        'foo_demand' => 'reset',
        'input_2'    => '15.0'
      } }
    } }

    before do
      scenario.user_values = { 'foo_demand' => 5.0 }
      scenario.save!
    end

    it_should_behave_like 'a successful scenario update'

    it 'removes the reset value' do
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('foo_demand')
    end

    it 'sets new input values' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 15.0)
    end
  end # Resetting a single value

  # --------------------------------------------------------------------------

  context 'Setting invalid scenario values' do
    let(:params) { {
      scenario: { area_code: nil, user_values: { 'foo_demand' => '-1.0' } }
    } }

    it_should_behave_like 'a failed scenario update'

    it 'warns about the invalid value' do
      updater.valid?

      expect(updater.errors[:base]).to \
        include('Input foo_demand cannot be less than 0.0')
    end
  end # Setting invalid scenario values

  # --------------------------------------------------------------------------

  context 'Setting an invalid input value' do
    let(:params) { {
      scenario: { user_values: { 'foo_demand' => '-1.0' } }
    } }

    it_should_behave_like 'a failed scenario update'
  end # Setting an invalid input value

  # --------------------------------------------------------------------------

  context 'Sending a non-hash user_values attribute' do
    before do
      scenario.update_attributes!(user_values: { 'foo_demand' => 1.0 })
    end

    let(:params) { {
      scenario: { user_values: nil }
    } }

    it_should_behave_like 'a successful scenario update'

    it 'does not change user_values' do
      scenario.reload
      expect(scenario.user_values).to eq({ 'foo_demand' => 1.0 })
    end
  end # Sending a non-hash user_values attribute

  # --------------------------------------------------------------------------

  context 'Changing a scenario which references an old input' do
    before do
      scenario.update_attributes!(user_values: { 'removed' => 1.0 })
    end

    let(:params) { {
      scenario: { user_values: { 'foo_demand' => '-1.0' } }
    } }

    it_should_behave_like 'a failed scenario update'

    it 'does not change the user values' do
      expect(scenario.reload.user_values).to eql({ 'removed' => 1.0 })
    end
  end # Changing a scenario which references an old input

  # --------------------------------------------------------------------------

  context 'Setting an area-disabled input' do
    let(:params) { {
      scenario: { user_values: {
        'foo_demand' => '1.0',
        'input_2'    => '50.0'
      } }
    } }

    before do
      input = Input.get('foo_demand')
      allow(input).to receive(:disabled_in_current_area?).and_return(true)
    end

    it_should_behave_like 'a successful scenario update'

    it 'should not set the disabled input' do
      pending 'should not save disabled inputs'
      updater.apply
      expect(scenario.reload.user_values).not_to have_key('foo_demand')
    end

    it 'should set the enabled input' do
      updater.apply
      expect(scenario.reload.user_values).to include('input_2' => 50.0)
    end
  end

  # ----------------------------------------------------------------------------

  context 'Setting an input in a scaled scenario' do
    let(:scenario) do
      ScenarioScaling.create!(
        scenario:       super(),
        area_attribute: 'number_of_residences',
        value:          1_000_000
      ).scenario
    end

    context 'when the input value is within the acceptable range' do
      let(:params) { {
        autobalance: false,
        scenario: { user_values: {
          # 5.0 is not an acceptable value in a non-scaled scenario (10.0 is
          # the minimum).
          'input_2' => '5.0'
        } }
      } }

      it_should_behave_like 'a successful scenario update'
    end

    context 'when the input value is not within the acceptable range' do
      let(:params) { {
        autobalance: false,
        scenario: { user_values: {
          # 50000 is an acceptable value in a non-scaled scenario.
          'input_2' => '50000'
        } }
      } }

      it_should_behave_like 'a failed scenario update'
    end
  end

  # --------------------------------------------------------------------------

  context 'Updating grouped inputs without the balancer' do
    context 'when the group adds up' do
      let(:params) { {
        autobalance: false,
        scenario: { user_values: {
          'grouped_input_one' => '75.0',
          'grouped_input_two' => '25.0'
        } }
      } }

      it_should_behave_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        expect(scenario.user_values).to include('grouped_input_one' => 75.0)
        expect(scenario.user_values).to include('grouped_input_two' => 25.0)
      end
    end # when the group adds up

    context 'when the input has been previously balanced' do
      let(:params) { {
        autobalance: false,
        scenario: { user_values: { 'grouped_input_one' => '100.0' } }
      } }

      before do
        scenario.balanced_values = {
          'grouped_input_one' => 50.0,
          'input_2'           => 100.0
        }
      end

      it_should_behave_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        expect(scenario.balanced_values).not_to have_key('grouped_input_one')
        expect(scenario.balanced_values).not_to have_key('grouped_input_two')
        expect(scenario.balanced_values).to     have_key('input_2')
      end
    end # when the input has been previously balanced

    context 'when related inputs have been previously balanced' do
      let(:params) { {
        autobalance: false,
        scenario: { user_values: { 'grouped_input_one' => '100.0' } }
      } }

      before do
        scenario.balanced_values = {
          'grouped_input_two' => 100.0,
          'input_2'           => 100.0
        }
      end

      it_should_behave_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        expect(scenario.balanced_values).not_to have_key('grouped_input_one')
        expect(scenario.balanced_values).not_to have_key('grouped_input_two')
        expect(scenario.balanced_values).to     have_key('input_2')
      end
    end # when related inputs have been previously balanced

    context 'when the group does not add up' do
      let(:params) { {
        autobalance: false,
        scenario: { user_values: {
          'grouped_input_one' => '75.0',
          'grouped_input_two' => '10.0'
        } }
      } }

      it_should_behave_like 'a failed scenario update'

      it 'should have an error message' do
        updater.apply

        expect(updater.errors[:base].any? { |error|
          error.match(/"grouped" group does not balance/)
        }).to be_truthy
      end
    end # when the group does not add up
  end # Updating grouped inputs without the balancer

  # --------------------------------------------------------------------------

  context 'Updating a grouped input with the balancer' do
    context 'when the values can be balanced' do
      let(:params) { {
        autobalance: true,
        scenario: { user_values: { 'grouped_input_one' => '75.0' } }
      } }

      it_should_behave_like 'a successful scenario update'

      it 'sets the user value' do
        updater.apply
        expect(scenario.reload.user_values).to eql('grouped_input_one' => 75.0)
      end

      it 'sets the balanced value' do
        updater.apply
        expect(scenario.reload.balanced_values).to eql('grouped_input_two' => 25.0)
      end
    end # when the values can be balanced

    context 'when providing all values' do
      let(:params) { {
        autobalance: true,
        scenario: { user_values: {
          'grouped_input_one' => '70.0',
          'grouped_input_two' => '30.0'
        } }
      } }

      it_should_behave_like 'a successful scenario update'

      it 'sets the user value' do
        updater.apply
        scenario.reload

        expect(scenario.user_values).to eql(
          'grouped_input_one' => 70.0,
          'grouped_input_two' => 30.0)
      end

      it 'sets no balanced values' do
        updater.apply
        expect(scenario.reload.balanced_values).to be_blank
      end
    end # when providing all values

    context 'when the provided values already balance' do
      let(:params) { {
        autobalance: true,
        scenario: { user_values: { 'grouped_input_one' => '100.0' } }
      } }
    end # when the provided values already balance

    context 'when setting a previously balanced value' do
      let(:params) { {
        autobalance: true,
        scenario: { user_values: { 'grouped_input_one' => '100.0' } }
      } }

      before do
        scenario.balanced_values = { 'grouped_input_one' => '25.0' }
      end

      it_should_behave_like 'a successful scenario update'

      it 'sets the user value' do
        updater.apply
        expect(scenario.reload.user_values).to eql('grouped_input_one' => 100.0)
      end

      it 'sets balanced values' do
        updater.apply
        expect(scenario.reload.balanced_values).to eql('grouped_input_two' => 0.0)
      end
    end # when setting a previously balanced value

    context 'when the values cannot be balanced' do
      let(:params) { {
        autobalance: true,
        scenario: { user_values: { 'grouped_input_one' => '9999999.0' } }
      } }

      it_should_behave_like 'a failed scenario update'
    end # when the values cannot be balanced
  end # Updating a grouped input with the balancer

end # ScenarioUpdater
