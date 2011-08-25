class AddQueryToInputs < ActiveRecord::Migration
  def self.up
    add_column :inputs, :query, :text
  end

  def self.down
    remove_column :inputs, :query
  end
end
