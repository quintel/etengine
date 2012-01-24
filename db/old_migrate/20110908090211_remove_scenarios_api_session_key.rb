class RemoveScenariosApiSessionKey < ActiveRecord::Migration
  def self.up
    remove_column :scenarios, :api_session_key
  end

  def self.down
    add_column :scenarios, :api_session_key, :string
  end
end
