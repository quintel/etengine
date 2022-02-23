# frozen_string_literal: true

APP_CONFIG = Rails.application.config_for(:config).with_indifferent_access

Rails.application.reloader.to_prepare do
  unless defined?(ETSOURCE_DIR)
    # Sort out the ETSource paths
    ETSOURCE_DIR = Etsource::Base.clean_path(APP_CONFIG.fetch(:etsource_working_copy))
    ETSOURCE_EXPORT_DIR = Etsource::Base.clean_path(APP_CONFIG.fetch(:etsource_export, 'etsource'))

    Atlas.data_dir = ETSOURCE_EXPORT_DIR

    # Ensure a user in development does not overwrite their ETSource repo by doing an import via the
    # admin UI.
    APP_CONFIG[:etsource_disable_export] = true if ETSOURCE_DIR == ETSOURCE_EXPORT_DIR

    # Ensure any old lazy files (from the previous time the application was loaded) are removed.
    Etsource::Dataset::Import.loader.expire_all! if APP_CONFIG[:etsource_lazy_load_dataset]
  end

  # We store objects in the cache which are no longer valid if the code is reloaded.
  Rails.cache.clear
end
