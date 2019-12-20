class CreateHeatNetworkOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :heat_network_orders do |t|
      t.references :scenario,
        type: :integer,
        foreign_key: true,
        index: { unique: true }

      t.text :order
    end
  end
end
