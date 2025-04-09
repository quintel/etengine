class SerializeUserValues < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Temporary model
  class ScenarioForMigration < ActiveRecord::Base
    self.table_name = 'scenarios'
  end

  require 'msgpack'

  def up
    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      original = ScenarioForMigration.find(scenario.id)
      yaml_data = original.read_attribute_before_type_cast("user_values")
      next if yaml_data.blank? || !yaml_data.is_a?(String)

      begin
        # Had to add other permitted_classes
        values = YAML.safe_load(yaml_data, permitted_classes: [Hash, Float, Integer, String, Symbol], aliases: true)

        next unless values.is_a?(Hash)
        msgpack_blob = values.to_h.to_msgpack

        ScenarioForMigration.find(id: scenario.id).update!(user_values: msgpack_blob)
      rescue => e
        Rails.logger.warn("Skipping scenario ##{scenario.id}: #{e.message}")
      end
    end

    change_column :scenarios, :user_values, :binary, limit: 16.megabytes
  end

end
