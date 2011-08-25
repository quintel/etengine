class AddV1LegacyUnitToInputs < ActiveRecord::Migration
  def self.up
    add_column :inputs, :v1_legacy_unit, :string
    Input.reset_column_information
  end

  def self.down
    remove_column :inputs, :v1_legacy_unit
  end
end
