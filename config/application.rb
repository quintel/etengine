require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Etm
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Etc/UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true

    ## Pseudo-modules
    # I packaged some classes/files separate folders
    # so we need to load them here. This is only for classes
    # that belong together but where it didn't make sense to
    # put them in a module.
    config.autoload_paths += Dir["#{Rails.root}/app/controllers/application_controller"]
    config.autoload_paths += Dir["#{Rails.root}/app/deprecated"]

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
