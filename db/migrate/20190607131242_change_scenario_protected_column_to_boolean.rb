class ChangeScenarioProtectedColumnToBoolean < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      change_table :scenarios do |t|
        dir.up { t.change :protected, :boolean }
        dir.down { t.change :protected, :integer, limit: 4 }
      end
    end
  end
end
