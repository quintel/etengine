class RemoveOldTables < ActiveRecord::Migration
  def self.up
  	drop_table :datasets
  	drop_table :dataset_carrier_data
  	drop_table :dataset_converter_data
  	drop_table :dataset_link_data
  	drop_table :dataset_slot_data


  	drop_table :blueprints
  	drop_table :blueprints_converters
  	drop_table :converters_groups
  	drop_table :links
  	drop_table :slots
  	drop_table :time_curve_entries
  	# I leave areas, graphs, converters, carriers, groups for another week or two
  	# they might come in handy.
  end

  def self.down
  	raise ActiveRecord::IrreversibleMigration
  end
end
