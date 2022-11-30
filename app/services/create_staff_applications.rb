# frozen_string_literal: true

# Creates OAuth applications for a given staff user.
module CreateStaffApplications
  def self.call(user)
    ETEngine::StaffApplications.applications.each do |app_config|
      next if StaffApplication.exists?(user:, name: app_config.key)

      app = user.oauth_applications.create!(
        app_config.to_model_attributes.merge(owner: user)
      )

      user.staff_applications.create!(
        name: app_config.key,
        application: app
      )
    end

    true
  end
end
