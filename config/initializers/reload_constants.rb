Rails.application.config.to_prepare do
  ActiveSupport::Reloader.to_prepare do
    cache_time = Rails.cache.read(NastyCache::MEMORY_CACHE_KEY)
    nl_data    = Etsource::Loader.instance.dataset('nl').data

    NastyCache.instance.expire_cache!

    # Retain the original cache time to prevent the next request from expiring.
    # all Atlas data.
    Rails.cache.write(NastyCache::MEMORY_CACHE_KEY, cache_time)

    # Create a new NL dataset with the original data. Shaves 2s off reloading
    # time in development.
    Etsource::Loader.instance.warm_dataset_with_data('nl', nl_data)
  end
end
