# frozen_string_literal: true

namespace :scenarios do
  # Temporary until session handles are implemented, when this task is removed with creator_id.
  desc 'Fills empty scenario creators from their earliest owner. Safe to run more than once'
  task backfill_creator_id: :environment do
    owners = ScenarioUser.where(role_id: User::ROLES.key(:scenario_owner)).where.not(user_id: nil)
    earliest_owner = owners.where('scenario_users.scenario_id = scenarios.id').order(:id).limit(1)
    missing = Scenario.where(creator_id: nil, id: owners.select(:scenario_id))
    updated = 0

    missing.in_batches(of: 10_000) do |batch|
      updated += batch.update_all("creator_id = (#{earliest_owner.select(:user_id).to_sql})")
    end

    puts "Updated #{updated} scenarios"
  end
end
