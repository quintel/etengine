class AddMetadataToScenarios < ActiveRecord::Migration[5.2]
  def change
    add_column :scenarios, :metadata, :text, limit: 65535
  end
end
