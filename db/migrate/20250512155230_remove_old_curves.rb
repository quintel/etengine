class RemoveOldCurves < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      scenario.attachments.find_each do |attachment|
        next unless attachment.curve?
        # Only destroy curves that exist in the new format
        next unless scenario.user_curves.exists?(key: attachment.key)

        attachment.destroy!
      end
    end
  end
end
