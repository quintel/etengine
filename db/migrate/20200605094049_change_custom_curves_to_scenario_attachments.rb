class ChangeCustomCurvesToScenarioAttachments < ActiveRecord::Migration[5.2]
  def up
    attachments = ActiveStorage::Attachment.where(record_type: 'Scenario')

    attachments.find_each do |attachment|
      begin
        scenario = Scenario.find(attachment.record_id)
        scen_attach = scenario.attachments.create!(key: attachment.name)

        attachment.record_type = 'ScenarioAttachment'
        attachment.record_id = scen_attach.id
        attachment.name = 'file'

        attachment.save!
      rescue ActiveRecord::RecordNotFound
        puts "Missing scenario #{attachment.record_id} for " \
             "attachment #{attachment.id}"
      end
    end
  end

  def down
    ActiveRecord::IrreversibleMigration
  end
end
