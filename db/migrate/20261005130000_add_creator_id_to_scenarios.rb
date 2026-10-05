# Temporary until session handles are implemented, when the column and this backfill are removed.
#
# Adds the user who created each scenario, and fills it for existing scenarios from their earliest
# coupled owner. Scenarios without one keep no creator.
class AddCreatorIdToScenarios < ActiveRecord::Migration[8.1]
  def up
    add_column(
      :scenarios, :creator_id, :integer,
      comment: 'Temporary until session handles are implemented'
    )

    say_with_time('Backfilling creator_id from scenario owners') { backfill }

    add_index(:scenarios, :creator_id)
  end

  def down
    remove_column(:scenarios, :creator_id)
  end

  # Sets creator_id from the earliest coupled owner row of each scenario that has none yet, so it
  # can run more than once. Returns the number of scenarios updated.
  def backfill
    exec_update(<<~SQL.squish)
      UPDATE scenarios
      INNER JOIN (
        SELECT scenario_users.scenario_id, scenario_users.user_id
        FROM scenario_users
        INNER JOIN (
          SELECT MIN(id) AS id
          FROM scenario_users
          WHERE role_id = #{User::ROLES.key(:scenario_owner)} AND user_id IS NOT NULL
          GROUP BY scenario_id
        ) AS first_owners ON first_owners.id = scenario_users.id
      ) AS creators ON creators.scenario_id = scenarios.id
      SET scenarios.creator_id = creators.user_id
      WHERE scenarios.creator_id IS NULL
    SQL
  end
end
