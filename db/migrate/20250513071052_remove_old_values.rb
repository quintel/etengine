class RemoveOldValues < ActiveRecord::Migration[7.1]
  def change
    remove_column :scenarios, :user_values_old
    remove_column :scenarios, :balanced_values_old
  end
end
