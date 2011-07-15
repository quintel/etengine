class UpdateFceSlidersUpdateType < ActiveRecord::Migration
  def self.up
    execute "UPDATE  `inputs` SET `update_type` = 'fce' WHERE `update_type` = 'lce';"
  end

  def self.down
  end
end
