class AddDeprecatedKeysToGqueries < ActiveRecord::Migration
  def self.up
    add_column :gqueries, :deprecated_key, :string
  end

  def self.down
    remove_column :gqueries, :deprecated_key
  end
end
