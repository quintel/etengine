class AddCreatedAtIndexToScenarios < ActiveRecord::Migration[5.2]
  def change
    add_index :scenarios, :created_at
  end
end
