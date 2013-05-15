raw_config = File.read("#{Rails.root}/config/config.yml")
APP_CONFIG = YAML.load(raw_config)[Rails.env].with_indifferent_access

if APP_CONFIG[:airbrake_api_key].present? && !APP_CONFIG[:standalone]
  Airbrake.configure do |config|
    config.api_key = APP_CONFIG[:airbrake_api_key]
  end
end

# Put ETSOURCE_DIR in here, so that it is accessible when loading
# with yaml box.
ETSOURCE_DIR = APP_CONFIG.fetch(:etsource_working_copy, 'etsource')
ETSOURCE_EXPORT_DIR = ENV['ETSOURCE_DIR'] || APP_CONFIG.fetch(:etsource_export, 'etsource')

# On staging we might want to see the backtrace
if Rails.env.production? && APP_CONFIG[:show_backtrace]
  Etm::Application.config.consider_all_requests_local = true
end
