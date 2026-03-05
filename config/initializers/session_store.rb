# frozen_string_literal: true

# Configure session store with same_site: :none to allow session cookies during OAuth redirects
# This is required for OAuth flows that redirect between different ports (e.g., 3000 <-> 3002)
Etm::Application.config.session_store :active_record_store,
  key: "_etengine",
  same_site: :none,   # Allow cookies during OAuth cross-port redirects
  secure: false       # HTTP is ok in development (must be true in production with HTTPS)
