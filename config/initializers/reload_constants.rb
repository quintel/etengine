Rails.application.config.to_prepare do
  Rails.application.reloader.to_prepare do
    dataset_key = Etsource::Config.default_dataset_key
    cache_time  = Rails.cache.read(NastyCache::MEMORY_CACHE_KEY)
    data        = Etsource::Loader.instance.dataset(dataset_key).data

    NastyCache.instance.expire_cache!

    # Retain the original cache time to prevent the next request from expiring.
    # all Atlas data.
    Rails.cache.write(NastyCache::MEMORY_CACHE_KEY, cache_time)

    # Create a new NL dataset with the original data. Shaves 2s off reloading
    # time in development.
    Etsource::Loader.instance.warm_dataset_with_data(dataset_key, data)
  end
end
