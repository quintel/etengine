class DropGqlTestCases < ActiveRecord::Migration
 
  def self.up
    drop_table :gql_test_cases if table_exists?(:gql_test_cases)
  end

  def self.down
  end
end
