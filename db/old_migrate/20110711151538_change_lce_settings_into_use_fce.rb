class ChangeLceSettingsIntoUseFce < ActiveRecord::Migration
  def self.up
    change_column :scenarios, :lce_settings, :boolean
    rename_column :scenarios, :lce_settings, :use_fce
  end

  def self.down
    rename_column :scenarios, :use_fce, :lce_settings
    change_column :scenarios, :lce_settings, :text
  end
end