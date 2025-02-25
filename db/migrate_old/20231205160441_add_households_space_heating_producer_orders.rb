class AddHouseholdsSpaceHeatingProducerOrders < ActiveRecord::Migration[7.0]
  def change
    create_table 'households_space_heating_producer_orders' do |t|
      t.integer 'scenario_id'
      t.text 'order'
      t.index ['scenario_id'], unique: true
    end

    add_foreign_key 'households_space_heating_producer_orders', 'scenarios'
  end
end
