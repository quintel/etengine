require 'spec_helper'

describe ScenarioUser do
  let(:scenario) { create(:scenario) }

  it { is_expected.to validate_inclusion_of(:role_id).in_array(User::ROLES.keys).with_message("unknown") }

  it { is_expected.to belong_to(:scenario) }
  it { is_expected.to belong_to(:user).optional }

  it 'validates on_save with user_email and no user_id set' do
    expect do
      create(:scenario_user,
        scenario: scenario,
        user: nil,
        user_email: 'test@test.com'
      )
    end.to_not raise_error
  end

  it 'validates on_save with user_id and no user_email set' do
    expect do
      create(:scenario_user,
        scenario: scenario,
        user: create(:user)
      )
    end.to_not raise_error
  end

  context 'when creating a new scenario user with a known email adres' do
    let(:user) { create(:user, ) }
    let(:email) { 'hi@me.com' }
    let(:scenario_user) { create(:scenario_user, user_id: user.id) }

    before { user }

    it 'sets the user on the scenario user' do
      expect(scenario_user.user_id).to eq(user.id)
    end

    it 'removes the email from the scenario_user' do
      expect(scenario_user.user_email).to be_nil
    end
  end

  it 'allows updating the role if not the last scenario owner' do
    # The first user added will automatically become the scenario owner
    scenario.user = create(:user)
    scenario_user = create(
      :scenario_user,
      scenario: scenario,
      role_id: User::ROLES.key(:scenario_owner)
    )

    scenario_user.update(role_id: User::ROLES.key(:scenario_viewer))

    expect(
      scenario_user.reload.role_id
    ).to be(User::ROLES.key(:scenario_viewer))
  end

  it 'allows destroying a record if not the last scenario owner' do
    # The first user added will automatically become the scenario owner
    scenario.user = create(:user)
    scenario_user = create(
      :scenario_user,
      scenario: scenario,
      role_id: User::ROLES.key(:scenario_owner)
    )

    scenario_user.destroy

    expect(
      scenario.scenario_users.count
    ).to be(1)
  end

  it 'raises an error when validating an incorrect email address' do
    expect do
      create(:scenario_user,
        scenario: scenario,
        user: nil,
        user_email: 'test'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'raises an error when both user and email address are present' do
    expect do
      create(:scenario_user,
        scenario: scenario,
        user: create(:user),
        user_email: 'test@test.com'
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'cancels an update action for the last owner of a scenario' do
    # The first user added will automatically become the scenario owner
    scenario.user = create(:user)

    scenario_user = scenario.scenario_users.first
    scenario_user.update(role_id: User::ROLES.key(:scenario_viewer))

    expect(
      scenario_user.reload.role_id
    ).to be(User::ROLES.key(:scenario_owner))
  end

  it 'cancels a destroy action for the last owner of a scenario if other users are present' do
    owner = create(:scenario_user, scenario: scenario, role_id: User::ROLES.key(:scenario_owner))
    owner.destroy

    expect(owner.reload).to_not be(nil)
  end

  it 'cancels a destroy action for the last owner of a scenario if its the last user' do
    # The first user added will automatically become the scenario owner
    owner = create(:scenario_user, scenario: scenario, role_id: User::ROLES.key(:scenario_owner))
    owner.destroy

    expect(
      scenario.scenario_users.count
    ).to be(1)
  end
end
