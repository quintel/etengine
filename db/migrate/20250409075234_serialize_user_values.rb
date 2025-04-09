class SerializeUserValues < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Temporary model that bypasses any custom serialization
  class ScenarioForMigration < ActiveRecord::Base
    self.table_name = 'scenarios'
  end

  require 'msgpack'

  def up
    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      # Use the migration model to get the raw YAML
      original = ScenarioForMigration.find(scenario.id)
      yaml_data = original.read_attribute_before_type_cast("user_values")
      next if yaml_data.blank? || !yaml_data.is_a?(String)

      begin
        # Parse the YAML.
        # Note: Widen permitted classes if your YAML contains more than just a Hash.
        values = YAML.safe_load(yaml_data, permitted_classes: [Hash, Float, Integer, String, Symbol], aliases: true)
        next unless values.is_a?(Hash)

        # Directly update the database column with a MessagePack-encoded blob.
        # This bypasses the normal model serializer.
        msgpack_blob = values.to_h.to_msgpack
        ScenarioForMigration.where(id: scenario.id).update_all(user_values: msgpack_blob)
      rescue => e
        Rails.logger.warn("Skipping scenario ##{scenario.id}: #{e.message}")
      end
    end

    # Finally, change the column type to binary so Rails knows to expect binary data.
    change_column :scenarios, :user_values, :binary, limit: 16.megabytes
  end

  # Down migration omitted for brevity.
end
