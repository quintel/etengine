# Cache store may be a symbol, or an array whose first value is a symbol.
store_name, * = Etm::Application.config.cache_store

if store_name == :dalli_store
  # Dalli (Memcached) in production.
  require 'action_dispatch/middleware/session/dalli_store'
  session_store = :dalli_store
else
  session_store = :cookie_store
end

Etm::Application.config.session_store(session_store, key: '_etengine')
