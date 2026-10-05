# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db/migrate/20261005130000_add_creator_id_to_scenarios')

# Temporary until session handles are implemented, when this file is removed with creator_id.
describe AddCreatorIdToScenarios do
  let(:scenario) { create(:scenario) }
  let(:first_owner) { create(:user) }
  let(:second_owner) { create(:user) }

  def add_user(user, role)
    create(:scenario_user, scenario:, user:, role_id: User::ROLES.key(role))
  end

  def backfill
    described_class.new.backfill
    scenario.reload
  end

  context 'with one owner' do
    before { add_user(first_owner, :scenario_owner) }

    it 'sets the owner as the creator' do
      expect { backfill }.to change(scenario, :creator_id).from(nil).to(first_owner.id)
    end
  end

  context 'with two owners' do
    before do
      add_user(first_owner, :scenario_owner)
      add_user(second_owner, :scenario_owner)
    end

    it 'sets the earliest owner as the creator' do
      expect { backfill }.to change(scenario, :creator_id).from(nil).to(first_owner.id)
    end
  end

  context 'with a collaborator added before the owner' do
    before do
      add_user(first_owner, :scenario_collaborator)
      add_user(second_owner, :scenario_owner)
    end

    it 'sets the owner as the creator' do
      expect { backfill }.to change(scenario, :creator_id).from(nil).to(second_owner.id)
    end
  end

  context 'with only a pending owner' do
    before do
      create(
        :scenario_user,
        scenario:,
        user: nil,
        user_email: 'pending@example.org',
        role_id: User::ROLES.key(:scenario_owner)
      )
    end

    it 'sets no creator' do
      expect { backfill }.not_to change(scenario, :creator_id).from(nil)
    end
  end

  context 'without users' do
    it 'sets no creator' do
      expect { backfill }.not_to change(scenario, :creator_id).from(nil)
    end
  end

  context 'with a creator already set' do
    before do
      add_user(first_owner, :scenario_owner)
      scenario.update!(creator_id: second_owner.id)
    end

    it 'keeps the creator' do
      expect { backfill }.not_to change(scenario, :creator_id).from(second_owner.id)
    end
  end

  context 'when run twice' do
    before do
      add_user(first_owner, :scenario_owner)
      backfill
    end

    it 'keeps the creator' do
      expect { backfill }.not_to change(scenario, :creator_id).from(first_owner.id)
    end

    it 'updates no scenarios' do
      expect(described_class.new.backfill).to eq(0)
    end
  end
end
