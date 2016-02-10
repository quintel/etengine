class AddUniqueConstraintOnFlexOrderScenarioId < ActiveRecord::Migration
  def change
    FlexibilityOrder.where(scenario_id: 0).delete_all

    add_index :flexibility_orders, :scenario_id, unique: true
  end
end
