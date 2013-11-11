raw_config = File.read("#{Rails.root}/config/config.yml")
APP_CONFIG = YAML.load(raw_config)[Rails.env].with_indifferent_access

if APP_CONFIG[:airbrake_api_key].present? && !APP_CONFIG[:standalone]
  Airbrake.configure do |config|
    config.api_key = APP_CONFIG[:airbrake_api_key]
  end
end

# Sort out the ETSource paths
ETSOURCE_DIR = Etsource::Base.clean_path(
  APP_CONFIG.fetch(:etsource_working_copy, 'etsource'))

ETSOURCE_EXPORT_DIR = Etsource::Base.clean_path(
  ENV['ETSOURCE_DIR'] || APP_CONFIG.fetch(:etsource_export, 'etsource'))

Atlas.data_dir = ETSOURCE_EXPORT_DIR

# Ensure a user in development does not overwrite their ETSource repo by doing
# an import via the admin UI.
if ETSOURCE_DIR == ETSOURCE_EXPORT_DIR
  APP_CONFIG[:etsource_disable_export] = true
end

# On staging we might want to see the backtrace
if Rails.env.production? && APP_CONFIG[:show_backtrace]
  Etm::Application.config.consider_all_requests_local = true
end

if APP_CONFIG[:etsource_lazy_load_dataset]
  # Ensure any old lazy files (from the previous time the application was
  # loaded) are removed.
  Etsource::Dataset::Import.loader.expire_all!
end
