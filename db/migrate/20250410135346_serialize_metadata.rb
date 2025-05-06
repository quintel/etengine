class SerializeMetadata < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  class ScenarioForMigration < ActiveRecord::Base
    self.table_name = 'scenarios'
  end

  require 'msgpack'

  def up
    change_column :scenarios, :metadata, :text, size: :medium
    add_column :scenarios, :metadata_binary, :binary, limit:64.kilobytes

    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      original = ScenarioForMigration.find(scenario.id)
      yaml_data = original.read_attribute_before_type_cast("metadata")
      next if yaml_data.blank? || !yaml_data.is_a?(String)

      begin
        # Had to add other permitted_classes
        values = YAML.safe_load(yaml_data, permitted_classes: [Hash, Float, Integer, String, Symbol], aliases: true)
        next unless values.is_a?(Hash)
        msgpack_blob = values.to_h.to_msgpack

        ScenarioForMigration.find(scenario.id).update!(metadata_binary: msgpack_blob)
      rescue => e
        Rails.logger.warn("Skipping scenario ##{scenario.id}: #{e.message}")
      end
    end

    rename_column :scenarios, :metadata, :metadata_old
    rename_column :scenarios, :metadata_binary, :metadata
  end
end
