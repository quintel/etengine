Rails.application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.cache_store = :memory_store, { size: 512 * (1024 ** 3) } # 512 Mb
  # config.cache_store = :dalli_store
  # config.cache_store = :file_store, '/tmp/cache'

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Mail options for Devise.
  config.action_mailer.default_url_options = {
    host: ENV['ACTION_MAILER_HOST'] || 'etengine.dev'
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.after_initialize do
    # Start ETSource reloader only when running as a server (i.e., not as a rake
    # task).
    if (defined?(Rails::Server) || defined?(Puma)) &&
          APP_CONFIG[:etsource_live_reload]
      Etsource::Reloader.start!
    end
  end
end
