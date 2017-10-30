Rails.application.config.to_prepare do
  ActiveSupport::Reloader.to_prepare do
    NastyCache.instance.expire_cache!
  end
end
