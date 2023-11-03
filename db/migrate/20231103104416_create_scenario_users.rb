class CreateScenarioUsers < ActiveRecord::Migration[7.0]
  def up
    # Create new table + indices
    create_table :scenario_users do |t|
      t.integer     :user_id, null: false
      t.integer     :scenario_id, null: false
      t.integer     :role_id, null: false
      t.string      :user_email, default: nil
    end

    add_index :scenario_users, [:scenario_id, :user_id], name: 'scenario_users_scenario_id_user_id_idx'
    add_index :scenario_users, :user_email, name: 'scenario_users_user_email_idx'

    # Create ScenarioUser relations for currently existing scenarios
    Scenario.where.not(owner_id: nil).in_batches.each do |scenario_batch|
      scenario_users = scenario_batch.pluck(:id, :owner_id)
      scenario_users.map! do |su|
        {
          scenario_id: su[0],
          user_id: su[1],
          role_id: User::ROLES.key(:scenario_owner),
          user_email: nil
        }
      end

      ScenarioUser.insert_all(scenario_users)
    end
  end

  def down
    remove_index :scenario_users, name: 'scenario_users_scenario_id_user_id_idx'
    remove_index :scenario_users, name: 'scenario_users_user_email_idx'
    drop_table :scenario_users
  end
end
