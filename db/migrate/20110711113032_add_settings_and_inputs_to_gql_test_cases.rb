class AddSettingsAndInputsToGqlTestCases < ActiveRecord::Migration
  def self.up
    add_column :gql_test_cases, :settings, :text, :limit => 16777215
    add_column :gql_test_cases, :inputs, :text, :limit => 16777215
  end

  def self.down
    remove_column :gql_test_cases, :inputs
    remove_column :gql_test_cases, :settings
  end
end
