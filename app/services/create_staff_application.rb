# frozen_string_literal: true

# Creates or updates an OAuth application for a given staff user.
#
# If the user already has an application with the same name, it will be updated and their chosen
# hostname will be preserved in both the URI and redirect URI.
module CreateStaffApplication
  extend Dry::Monads[:result]

  def self.call(user, app_config, uri: nil)
    staff_app = user.staff_applications.find_or_initialize_by(name: app_config.key)
    app = staff_app.application || user.oauth_applications.new

    uri = URI.parse(uri || app.uri || app_config.uri)

    uri.path = ''
    uri.query = nil
    uri.fragment = nil

    redirect_uri = uri.dup
    redirect_uri.path = app_config.redirect_path

    app.attributes = app_config.to_model_attributes.merge(
      owner: user,
      uri: uri.to_s,
      redirect_uri: redirect_uri.to_s
    )

    return Failure(app) unless app.save

    staff_app.name = app_config.key
    staff_app.application = app

    staff_app.save ? Success(staff_app) : Failure(staff_app)
  end
end
