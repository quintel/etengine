class AddMinDemandAndMaxDemandToDatasetLinks < ActiveRecord::Migration
  def self.up
    add_column :dataset_link_data, :min_demand, :integer, :limit => 8
    add_column :dataset_link_data, :max_demand, :integer, :limit => 8
  end

  def self.down
    remove_column :dataset_link_data, :min_demand
    remove_column :dataset_link_data, :max_demand
  end
end