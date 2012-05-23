# Caches and persists an object across requests in the memory of the
# server process. Use it when caching with memcached is too slow. 
#
# Caveats: Using NastyCache local store with the Qernel Graph 
#          makes the app NO LONGER THREADSAFE
#
# @example Add this to your application_controller.rb
#
#   before_filter :initialize_memory_cache
#
#   def initialize_memory_cache
#     NastyCache.instance.initialize_request
#   end
#    
# @example setting and getting
#
#   NastyCache.instance.set("large_blob", "foo")
#   NastyCache.instance.get("large_blob")
#
# @example fetching
#
#   NastyCache.instance.fetch("large_blob") do
#     # ...
#   end
#
# @example fetching with :cache => true will also cache it
#
#   NastyCache.instance.fetch_cached("large_blob") { 'foo' }
#   # equivalent to:
#   NastyCache.instance.fetch("large_blob", :cache => true) { 'foo' }
#   # translates to:
#   NastyCache.instance.fetch("large_blob") do
#     Rails.cache.fetch("NastyCache/local_timestamp/large_blob") do
#       # ...
#     end
#   end 
#
# @example expiring cache across server instances
# 
#   NastyCache.instances.expire!
#   # => This will expire all instances across server instances
#   #    the next time they call #initialize_request.
#   #    This should be equivalent of restarting the server.
#
class NastyCache
  include Singleton

  MEMORY_CACHE_KEY = "NastyCache#timestamp"

  attr_accessor :local_timestamp

  def initialize
    @local_timestamp = init_timestamp
    @cache_store = {}
  end

  def initialize_request
    if expired?
      expire_local!
    else
      Rails.logger.info("NastyCache(#{Process.pid})#cached: keys: #{@cache_store.keys.join(", ")}")
    end
  end

  # Expires both local (@cache_store) and Rails.cache 
  # this is equivalent of a server restart.
  def expire!
    Rails.logger.info("NastyCache(#{Process.pid})#expire!")
    expire_cache!
    mark_expired!
    expire_local!
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
  def fetch_cached(key, &block)
    fetch(key, :cache => true, &block)
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

##############
# protected
##############

  # Expires Rails.cache. Easiest way is to Rails.cache.clear
  # Otherwise you could track the keys cached by MemoryCache in an
  # instance variable (e.g. @cached_keys), and delete them here:
  #    @cached_keys.each{|k| Rails.cache.delete(k) }
  def expire_cache!
    Rails.cache.clear
  end

  # 'broadcasts' that the cache has expired.
  def mark_expired!
    Rails.cache.write(MEMORY_CACHE_KEY, DateTime.now)
  end

  def expire_local!
    Rails.logger.info("NastyCache(#{Process.pid})#expire: timestamp: #{local_timestamp} (local) / #{global_timestamp} (global)")
    @local_timestamp = global_timestamp
    Rails.logger.info("NastyCache#expire: keys #{@cache_store.keys.join(", ")}")
    @cache_store = {}
  end

  def expired?
    local_timestamp != global_timestamp
  end

  def init_timestamp
    Rails.cache.fetch(MEMORY_CACHE_KEY) { DateTime.now }
  end

  def global_timestamp
    Rails.cache.read(MEMORY_CACHE_KEY)
  end

  def rails_cache_key(key)
    ["NastyCache", local_timestamp, key].join('/')
  end
end