# Caches and persists an object across requests in the memory of the
# server process. Use it when caching with memcached is too slow. 
#
# @example in your application controller
#
#   before_filter :initialize_memory_cache
#
#   def initialize_memory_cache
#     EtCache.instance.reset_if_expired
#   end
#    
# @example:
#
#   EtCache.instance.set("large_blob", "foo")
#   EtCache.instance.get("large_blob")
#   EtCache.instance.fetch("large_blob") do
#     # ...
#   end
#
# @example expiring cache across server instances
# 
#   EtCache.instances.expire!
#   # => This will expire all instances across server instances
#   #    the next time they call #reset_if_expired.
#
# @example Use together with Rails.cache
# 
#   EtCache.instance.fetch("large_blob") do
#     Rails.cache.fetch("large_blob") do
#       # ...
#     end
#   end 
#
#
class EtCache
  include Singleton

  MEMORY_CACHE_KEY = "EtCache#cache_timestamp"

  attr_accessor :local_cache_timestamp

  def initialize
    @local_cache_timestamp = nil
    @cache_store = {} 
  end

  def global_cache_timestamp
    Rails.cache.read(MEMORY_CACHE_KEY)
  end

  def expire!
    Rails.cache.clear
    Rails.cache.write(MEMORY_CACHE_KEY, DateTime.now.to_i)
    Rails.logger.info("EtCache#expire!")
    reset_if_expired
  end

  def expired?
    local_cache_timestamp != global_cache_timestamp
  end

  def reset_if_expired
    if expired?
      local_cache_timestamp = global_cache_timestamp
      @cache_store = {}
    else
      Rails.logger.info("EtCache#keys: #{@cache_store.keys.join(", ")}")
    end
  end

  def fetch(key, opts = {})
    if @cache_store.has_key?(key)
      get(key, opts)
    else
      value = if opts[:cache] == true
        Rails.cache.fetch(rails_cache_key(key)) { yield }
      else
        yield
      end
      set(key, value)
    end
  end 

  # alias to fetch(key, cache: true)
  def fetch_cached(key)
    fetch(key, :cache => true)
  end

  def rails_cache_key(key)
    ["EtCache", global_cache_timestamp, key].join('/')
  end

  def get(key, opts = {})
    if opts[:cache] == true
      @cache_store[key] || Rails.cache.read(rails_cache_key(key))
    else
      @cache_store[key]
    end
  end

  def set(key, value)
    @cache_store[key] = value
  end
end