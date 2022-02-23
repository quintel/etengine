# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  config.cache_store = :memory_store, { size: 512 * (1024**3) } # 512 Mb
  # config.cache_store = :dalli_store
  # config.cache_store = :file_store, '/tmp/cache'

  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Mail options for Devise.
  config.action_mailer.default_url_options = {
    host: ENV['ACTION_MAILER_HOST'] || 'etengine.dev'
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Run ActiveJob inline.
  config.active_job.queue_adapter = :inline

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateCheck

  config.after_initialize do
    # Start ETSource reloader only when running as a server (i.e., not as a rake
    # task).
    if (defined?(Rails::Server) || defined?(Puma)) &&
          APP_CONFIG[:etsource_live_reload]
      Etsource::Reloader.start!
    end
  end
end
