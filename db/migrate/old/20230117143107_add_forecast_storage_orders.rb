class AddForecastStorageOrders < ActiveRecord::Migration[7.0]
  def change
    create_table 'forecast_storage_orders' do |t|
      t.integer 'scenario_id'
      t.text 'order'
      t.index ['scenario_id'], unique: true
    end

    add_foreign_key 'forecast_storage_orders', 'scenarios'
  end
end
