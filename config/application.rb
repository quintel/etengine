require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Etm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Etc/UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true
    config.i18n.available_locales = %i[en nl]
    config.i18n.default_locale = :en

    config.active_support.deprecation = :log
    config.active_support.message_serializer = :message_pack

    config.encoding = "utf-8"

    config.filter_parameters << :password

    config.generators do |g|
      g.template_engine :haml
      g.test_framework  :rspec, :fixture => false
    end

    # config.assets.enabled = true

    # Store files locally.
    config.active_storage.service = :local

    Config.setup do |config|
      config.const_name = 'Settings'
    end

    local_settings_file = Rails.root.join('config/settings.local.yml')
    if local_settings_file.exist?
      Settings.add_source!(local_settings_file.to_s)
      Settings.reload!
    end

    # Mail

    if (email_conf = Rails.root.join('config/email.yml')).file?
      email_env_conf = YAML.load_file(email_conf)[Rails.env]

      if email_env_conf
        config.action_mailer.smtp_settings = email_env_conf.symbolize_keys
      else
        raise "Missing e-mail settings for #{ Rails.env.inspect } environment"
      end
    end

    # Allow commonly used classes in `serialize` columns (user and balanced values)
    config.active_record.yaml_column_permitted_classes =
      [Symbol, ActiveSupport::HashWithIndifferentAccess]
  end

  Date::DATE_FORMATS[:default] = "%d-%m-%Y"
end
