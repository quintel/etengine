class SerializeActiveCouplings < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  class ScenarioForMigration < ActiveRecord::Base
    self.table_name = 'scenarios'
  end

  require 'msgpack'

  def up
    change_column :scenarios, :active_couplings, :text, size: :medium
    add_column :scenarios, :active_couplings_binary, :binary, limit: 64.kilobytes

    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      original = ScenarioForMigration.find(scenario.id)
      yaml_data = original.read_attribute_before_type_cast("active_couplings")
      next if yaml_data.blank? || !yaml_data.is_a?(String)

      begin
        values = YAML.safe_load(yaml_data, permitted_classes: [Array, String, Symbol], aliases: true)
        next unless values.is_a?(Array)
        msgpack_blob = values.to_msgpack
        ScenarioForMigration.find(scenario.id).update!(active_couplings_binary: msgpack_blob)
      rescue => e
        Rails.logger.warn("Skipping scenario ##{scenario.id}: #{e.message}")
      end
    end

    rename_column :scenarios, :active_couplings, :active_couplings_old
    rename_column :scenarios, :active_couplings_binary, :active_couplings
  end

end
