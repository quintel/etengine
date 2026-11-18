class AddBoundToScenarios < ActiveRecord::Migration[7.0]
  def change
    add_column(:scenarios, :bound, :boolean, default: false, null: false)
  end
end
