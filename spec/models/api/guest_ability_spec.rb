# frozen_string_literal: true

require 'cancan/matchers'

RSpec.describe Api::GuestAbility do
  subject(:ability) { described_class.new }

  let(:user) { create(:user) }

  # Read

  it 'may view an unowned public scenario' do
    expect(ability).to be_able_to(:read, create(:scenario, user: nil, private: false))
  end

  it 'may view an owned public scenario' do
    expect(ability).to be_able_to(:read, create(:scenario, user:, private: false))
  end

  it 'may not view a private scenario' do
    expect(ability).not_to be_able_to(:read, create(:scenario, user:, private: true))
  end

  # Update

  it 'may change an unowned public scenario' do
    expect(ability).to be_able_to(:update, create(:scenario, user: nil, private: false))
  end

  it 'may not change an owned public scenario' do
    expect(ability).not_to be_able_to(:update, create(:scenario, user:, private: false))
  end

  it 'may not change an owned private scenario' do
    expect(ability).not_to be_able_to(:update, create(:scenario, user:, private: true))
  end

  it 'may clone an unowned public scenario' do
    expect(ability).to be_able_to(:clone, create(:scenario, user: nil, private: false))
  end

  it 'may clone an owned public scenario' do
    expect(ability).to be_able_to(:clone, create(:scenario, user:, private: false))
  end

  it 'may not clone a private scenario' do
    expect(ability).not_to be_able_to(:clone, create(:scenario, user:, private: true))
  end

  # Delete

  it 'may not delete an unowned public scenario' do
    expect(ability).not_to be_able_to(:destroy, create(:scenario, private: false))
  end

  it 'may not delete an owned public scenario' do
    expect(ability).not_to be_able_to(:destroy, create(:scenario, user:, private: false))
  end

  it 'may not delete a private scenario' do
    expect(ability).not_to be_able_to(:destroy, create(:scenario, user:, private: true))
  end
end
