class DisallowNullKeepCompatibleOrPrivate < ActiveRecord::Migration[7.0]
  def up
    Scenario.where(keep_compatible: nil).update_all(keep_compatible: false)
    Scenario.where(private: nil).update_all(private: false)

    change_column :scenarios, :keep_compatible, :boolean, default: false, null: false
    change_column :scenarios, :private, :boolean, default: false, null: false
  end

  def down
    change_column :scenarios, :keep_compatible, :boolean, null: false
    change_column :scenarios, :private, :boolean, null: false
  end
end
