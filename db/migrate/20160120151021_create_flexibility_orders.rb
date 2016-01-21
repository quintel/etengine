class CreateFlexibilityOrders < ActiveRecord::Migration
  def change
    create_table :flexibility_orders do |t|
      t.integer :scenario_id
      t.text :order
    end
  end
end
