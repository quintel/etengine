require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Etm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Etc/UTC'

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

    # Add this for Spork
    if Rails.env.test?
      initializer :after => :initialize_dependency_mechanism do
        ActiveSupport::Dependencies.mechanism = :load
      end
    end
  end

  require_relative '../lib/instrumentable'
  require_relative '../lib/node_positions'
  require_relative '../app/models/qernel/errors'

  Date::DATE_FORMATS[:default] = "%d-%m-%Y"
end

GC_DISABLING_HACK_ENABLED = true
