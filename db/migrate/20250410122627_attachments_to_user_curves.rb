require 'etengine/scenario_migration'

class AttachmentsToUserCurves < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios(raise_if_no_changes: false) do |scenario|
      scenario_migrated = false

      scenario.attachments.find_each do |attachment|
        next unless attachment.curve?
        next if scenario.user_curves.exists?(key: attachment.key)

        begin
          binary = attachment.file.download   # Download the binary file data stored via ActiveStorage.
          tempfile = Tempfile.new(["curve", ".csv"])
          tempfile.binmode                    # Switch the tempfile to binary mode so we can write raw binary data.
          tempfile.write(binary)              # Write the downloaded binary data into the tempfile.
          tempfile.rewind                     # Rewind the file pointer to the beginning of the file.

          file_stub = ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile,
            filename: attachment.key
          )

          config = Etsource::Config.user_curves[attachment.key.chomp('_curve')]
          next if config.nil?

          service = CurveHandler::Services::AttachService.new(config, file_stub, scenario, attachment.metadata_json)

          if service.call(false)
            # attachment.destroy!
            scenario_migrated = true
          end
        rescue => e
          Rails.logger.error "Attachment #{attachment.id} failed for scenario #{scenario.id}: #{e.message}"
        ensure
          tempfile.close                  # release any resources
          tempfile.unlink                 # delete from disk
        end
      end

      # Marks the scenario as changed so it's counted by ScenarioMigration.
      scenario.touch if scenario_migrated
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
