class ChangeScenarioUserToOwner < ActiveRecord::Migration[7.0]
  def change
    rename_column :scenarios, :user_id, :owner_id
  end
end
