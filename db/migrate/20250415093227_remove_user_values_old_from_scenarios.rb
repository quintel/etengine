class RemoveUserValuesOldFromScenarios < ActiveRecord::Migration[7.1]
  def change
    remove_column :scenarios, :user_values_old, :text
  end
end
