class SerializeBalancedValues < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Temporary model
  class ScenarioForMigration < ActiveRecord::Base
    self.table_name = 'scenarios'
  end

  require 'msgpack'

  def up
    change_column :scenarios, :balanced_values, :text, size: :medium
    add_column :scenarios, :balanced_values_binary, :binary, limit: 16.megabytes

    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      original = ScenarioForMigration.find(scenario.id)
      yaml_data = original.read_attribute_before_type_cast("balanced_values")
      next if yaml_data.blank? || !yaml_data.is_a?(String)

      begin
        values = YAML.safe_load(yaml_data, permitted_classes: [Hash, Float, Integer, String, Symbol], aliases: true)
        next unless values.is_a?(Hash)
        msgpack_blob = values.to_h.to_msgpack
        ScenarioForMigration.find(scenario.id).update!(balanced_values_binary: msgpack_blob)
      rescue => e
        Rails.logger.warn("Skipping scenario ##{scenario.id}: #{e.message}")
      end
    end

    rename_column :scenarios, :balanced_values, :balanced_values_old
    rename_column :scenarios, :balanced_values_binary, :balanced_values
  end

end
