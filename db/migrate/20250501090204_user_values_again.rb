class UserValuesAgain < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      yaml_data = scenario.read_attribute_before_type_cast("user_values_old")
      next if yaml_data.blank? || !yaml_data.is_a?(String)

      begin
        # Had to add other permitted_classes
        values = YAML.safe_load(yaml_data, permitted_classes: [Hash, Float, Integer, String, Symbol], aliases: true)

        next unless values.is_a?(Hash)

        scenario.user_values = values
      rescue => e
        Rails.logger.warn("Skipping scenario ##{scenario.id}: #{e.message}")
      end
    end
  end
end
