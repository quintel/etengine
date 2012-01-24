class ChangeGqlTestCasesInstructionToMediumText < ActiveRecord::Migration
  def self.up
    change_column :gql_test_cases, :instruction, :text, :limit => 16777215
  end

  def self.down
  end
end
