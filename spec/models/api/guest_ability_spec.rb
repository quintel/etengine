# frozen_string_literal: true

require 'cancan/matchers'

RSpec.describe Api::GuestAbility do
  subject(:ability) { described_class.new }

  let(:user) { create(:user) }
  let!(:public_scenario) { create(:scenario, user: nil, private: false) }
  let!(:owned_public_scenario) { create(:scenario, user: user, private: false) }
  let!(:owned_private_scenario) { create(:scenario, user: user, private: true) }

  # Read

  it 'may view an unowned public scenario' do
    expect(ability).to be_able_to(:read, public_scenario)
  end

  it 'may view an owned public scenario' do
    expect(ability).to be_able_to(:read, owned_public_scenario)
  end

  it 'may not view a private scenario' do
    expect(ability).not_to be_able_to(:read, owned_private_scenario)
  end

  # Update

  it 'may change an unowned public scenario' do
    expect(ability).to be_able_to(:update, public_scenario)
  end

  it 'may not change an owned public scenario' do
    expect(ability).not_to be_able_to(:update, owned_public_scenario)
  end

  it 'may not change an owned private scenario' do
    expect(ability).not_to be_able_to(:update, owned_private_scenario)
  end

  it 'may clone an unowned public scenario' do
    expect(ability).to be_able_to(:clone, public_scenario)
  end

  it 'may clone an owned public scenario' do
    expect(ability).to be_able_to(:clone, owned_public_scenario)
  end

  it 'may not clone a private scenario' do
    expect(ability).not_to be_able_to(:clone, owned_private_scenario)
  end

  # Delete

  it 'may not delete an unowned public scenario' do
    expect(ability).not_to be_able_to(:destroy, public_scenario)
  end

  it 'may not delete an owned public scenario' do
    expect(ability).not_to be_able_to(:destroy, owned_public_scenario)
  end

  it 'may not delete a private scenario' do
    expect(ability).not_to be_able_to(:destroy, owned_private_scenario)
  end
end
