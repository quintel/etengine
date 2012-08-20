class AddBalancedValuesToScenarios < ActiveRecord::Migration
  def change
    add_column :scenarios, :balanced_values, :text
  end
end
