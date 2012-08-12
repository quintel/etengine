require 'spec_helper'

describe Api::V3::ScenarioUpdater do

  shared_examples_for 'a successful scenario update' do
    it 'is valid' do
      updater.should be_valid
      updater.errors.should be_blank
    end

    it 'saves the changes' do
      updater.apply.should be_true
    end
  end

  shared_examples_for 'a failed scenario update' do
    it 'is not valid' do
      updater.should_not be_valid
      updater.errors.should_not be_blank
    end

    it 'does not save any changes' do
      updater.apply.should be_false
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

      new_attributes.should eql(old_attributes)
      scenario.user_values.should eql(user_values)
      scenario.balanced_values.should eql(balanced_values)
    end
  end

  # --------------------------------------------------------------------------

  let(:scenario) { FactoryGirl.create(:scenario) }
  let(:updater)  { Api::V3::ScenarioUpdater.new(scenario, params) }

  before do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  # --------------------------------------------------------------------------

  context 'With no user parameters' do
    let(:params) { Hash.new }

    it_should_behave_like 'a successful scenario update'

    it 'makes no changes' do
      scenario.should_not_receive(:save)
      updater.apply
    end
  end # With no user parameters

  # --------------------------------------------------------------------------

  context 'With a clean scenario' do
    let(:params) { {
      scenario: { user_values: { 'foo_demand' => '10.0' } }
    } }

    it_should_behave_like 'a successful scenario update'

    it 'sets the input values' do
      updater.apply
      scenario.reload

      scenario.user_values.should eql({ 'foo_demand' => 10.0 })
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
      scenario.reload.user_values.should include('foo_demand' => 10.0)
    end

    it 'sets new input values' do
      updater.apply
      scenario.reload.user_values.should include('input_2' => 15.0)
    end
  end # When the scenario has existing values

  # --------------------------------------------------------------------------

  context 'Resetting an entire scenario' do
    let(:params) { { reset: true } }

    before do
      scenario.user_values = { 'foo_demand' => '5.0' }
      scenario.save!
    end

    it_should_behave_like 'a successful scenario update'

    it 'removes all input values' do
      updater.apply
      scenario.reload.user_values.should be_blank
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
      scenario.save!
    end

    it_should_behave_like 'a successful scenario update'

    it 'sets new values' do
      updater.apply
      scenario.reload.user_values.should include('foo_demand' => 1.0)
    end

    it 'removes unspecified input values' do
      updater.apply
      scenario.reload.user_values.should_not have_key('bar_demand')
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
      scenario.reload.user_values.should_not have_key('foo_demand')
    end

    it 'sets new input values' do
      updater.apply
      scenario.reload.user_values.should include('input_2' => 15.0)
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

      updater.errors[:base].should \
        include('Input foo_demand cannot be less than 0')
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

  context 'Setting an area-disabled input' do
    let(:params) { {
      scenario: { user_values: {
        'foo_demand' => '1.0',
        'input_2'    => '50.0'
      } }
    } }

    before do
      input = Input.get('foo_demand')
      input.stub(:disabled_in_current_area?).and_return(true)
    end

    it_should_behave_like 'a successful scenario update'

    it 'should not set the disabled input' do
      pending 'should not save disabled inputs' do
        updater.apply
        scenario.reload.user_values.should_not have_key('foo_demand')
      end
    end

    it 'should set the enabled input' do
      updater.apply
      scenario.reload.user_values.should include('input_2' => 50.0)
    end
  end

  # --------------------------------------------------------------------------

  context 'Updating grouped inputs without the balancer' do
    context 'when the group adds up' do
      let(:params) { {
        scenario: { user_values: {
          'grouped_input_one' => '75.0',
          'grouped_input_two' => '25.0'
        } }
      } }

      it_should_behave_like 'a successful scenario update'

      it 'sets the user values' do
        updater.apply
        scenario.reload

        scenario.user_values.should include('grouped_input_one' => 75.0)
        scenario.user_values.should include('grouped_input_two' => 25.0)
      end
    end # when the group adds up

    context 'when the input has been previously balanced' do
      let(:params) { {
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

        scenario.balanced_values.should_not have_key('grouped_input_one')
        scenario.balanced_values.should_not have_key('grouped_input_two')
        scenario.balanced_values.should     have_key('input_2')
      end
    end # when the input has been previously balanced

    context 'when related inputs have been previously balanced' do
      let(:params) { {
        scenario: { user_values: { 'grouped_input_one' => '100.0' } }
      } }

      before do
        scenario.balanced_values = {
          'grouped_input_two' => 100.0,
          'input_2'           => 100.0
        }
      end

      it_should_behave_like 'a successful scenario update'

      it 'sets the user values', focus: true do
        updater.apply
        scenario.reload

        scenario.balanced_values.should_not have_key('grouped_input_one')
        scenario.balanced_values.should_not have_key('grouped_input_two')
        scenario.balanced_values.should     have_key('input_2')
      end
    end # when related inputs have been previously balanced

    context 'when the group does not add up' do
      let(:params) { {
        scenario: { user_values: {
          'grouped_input_one' => '75.0',
          'grouped_input_two' => '10.0'
        } }
      } }

      it_should_behave_like 'a failed scenario update'

      it 'should have an error message' do
        updater.apply

        updater.errors[:base].should \
          include('"grouped" group does not balance')
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
        scenario.reload.user_values.should eql('grouped_input_one' => 75.0)
      end

      it 'sets the balanced value' do
        updater.apply
        scenario.reload.balanced_values.should eql('grouped_input_two' => 25.0)
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

        scenario.user_values.should eql(
          'grouped_input_one' => 70.0,
          'grouped_input_two' => 30.0)
      end

      it 'sets no balanced values' do
        updater.apply
        scenario.reload.balanced_values.should be_blank
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
        scenario.reload.user_values.should eql('grouped_input_one' => 100.0)
      end

      it 'sets balanced values' do
        updater.apply
        scenario.reload.balanced_values.should eql('grouped_input_two' => 0.0)
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
