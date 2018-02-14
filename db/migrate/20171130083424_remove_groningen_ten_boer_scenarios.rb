class RemoveGroningenTenBoerScenarios < ActiveRecord::Migration[5.1]
  def up
    Scenario.where(area_code: 'groningen_ten_boer').destroy_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "can't be undone"
  end
end
