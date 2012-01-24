class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :areas, :parent_id
    add_index :blueprints, :blueprint_model_id
    add_index :blueprints_converters, [:converter_id, :blueprint_id]
    add_index :carriers, :carrier_id
    add_index :carriers, :key
    add_index :constraints, :key
    add_index :converter_positions, :converter_id
    add_index :converters_groups, [:converter_id, :group_id]
    add_index :dataset_carrier_data, :carrier_id
    add_index :dataset_converter_data, :converter_id
    add_index :dataset_link_data, :link_id
    add_index :dataset_slot_data, :slot_id
    add_index :gqueries, :key
    add_index :gqueries_gquery_groups, [:gquery_id, :gquery_group_id]
    add_index :graphs, :blueprint_id
    add_index :groups, :group_id
    add_index :historic_serie_entries, :historic_serie_id
    add_index :links, :parent_id
    add_index :links, :child_id
    add_index :links, :carrier_id
    add_index :output_elements, :output_element_type_id
    add_index :policy_goals, :key
    add_index :query_table_cells, :query_table_id
    add_index :scenarios, :in_start_menu
    add_index :scenarios, :user_id
    add_index :slots, :converter_id
    add_index :slots, :carrier_id
  end

  def self.down
  end
end
