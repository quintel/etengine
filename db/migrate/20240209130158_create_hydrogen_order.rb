class CreateHydrogenOrder < ActiveRecord::Migration[7.0]
  def change
    create_table :hydrogen_orders do |t|
      t.integer 'scenario_id'
      t.text 'order'
      t.index ['scenario_id'], unique: true
    end

    add_foreign_key 'hydrogen_orders', 'scenarios'
  end
end
