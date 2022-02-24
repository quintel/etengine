require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Etm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Etc/UTC'

    config.eager_load_paths << Rails.root.join("lib")

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true

    config.active_support.deprecation = :log

    config.encoding = "utf-8"

    config.filter_parameters << :password

    config.generators do |g|
      g.template_engine :haml
      g.test_framework  :rspec, :fixture => false
    end

    config.assets.enabled = true
    config.assets.precompile += ['graph.js', 'graph.css']

    # Store files locally.
    config.active_storage.service = :local

    # Mail

    if (email_conf = Rails.root.join('config/email.yml')).file?
      email_env_conf = YAML.load_file(email_conf)[Rails.env]

      if email_env_conf
        config.action_mailer.smtp_settings = email_env_conf.symbolize_keys
      else
        raise "Missing e-mail settings for #{ Rails.env.inspect } environment"
      end
    end
  end

  Date::DATE_FORMATS[:default] = "%d-%m-%Y"
end

GC_DISABLING_HACK_ENABLED = true
