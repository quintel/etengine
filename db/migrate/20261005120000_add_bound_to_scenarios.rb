class AddBoundToScenarios < ActiveRecord::Migration[8.1]
  def change
    add_column(:scenarios, :bound, :boolean, default: false, null: false)
  end
end
