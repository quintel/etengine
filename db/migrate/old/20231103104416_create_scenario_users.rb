class CreateScenarioUsers < ActiveRecord::Migration[7.0]
  def up
    # Create new table + indices
    create_table :scenario_users do |t|
      t.integer :scenario_id, null: false
      t.integer :role_id, null: false
      t.integer :user_id, default: nil
      t.string  :user_email, default: nil
    end

    add_index :scenario_users, [:scenario_id, :user_id], unique: true,    name: 'scenario_users_scenario_id_user_id_idx'
    add_index :scenario_users, [:scenario_id, :user_email], unique: true, name: 'scenario_users_scenario_id_user_email_idx'

    # Create ScenarioUser relations for currently existing scenarios, in batches of 1000
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

    remove_foreign_key 'scenarios', 'users'
    remove_column :scenarios, :owner_id
  end

  def down
    add_column :scenarios, :owner_id
    add_foreign_key 'scenarios', 'users'

    Scenario.where('NOT scenario_users IS NULL').each do |scenario|
      scenario.update(owner_id: scenario_users.find_by(role_id: 3).first.user_id, touch: false)
    end

    remove_index :scenario_users, name: 'scenario_users_scenario_id_user_id_idx'
    remove_index :scenario_users, name: 'scenario_users_scenario_id_user_email_idx'
    drop_table :scenario_users
  end
end
