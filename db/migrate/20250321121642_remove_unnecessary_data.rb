class RemoveUnnecessaryData < ActiveRecord::Migration[7.0]
  def up
    drop_table :old_users, if_exists: true
    drop_table :personal_access_tokens, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Cannot restore dropped tables"
  end
end
