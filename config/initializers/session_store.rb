# frozen_string_literal: true

# Cache store may be a symbol, or an array whose first value is a symbol.
store_name, * = Etm::Application.config.cache_store

if store_name == :dalli_store
  # Dalli (Memcached) in production.
  require 'action_dispatch/middleware/session/dalli_store'

  Rails.application.config.session_store(
    ActionDispatch::Session::CacheStore, expire_after: 20.minutes
  )
else
  Rails.application.config.session_store(:cookie_store, key: '_etengine')
end
