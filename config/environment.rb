# Load the rails application
require File.expand_path('../application', __FILE__)
Encoding.default_external = Encoding::UTF_8


# Initialize the rails application
Etm::Application.initialize!

# DalliStore
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # Only works with DalliStore
    Rails.cache.reset if forked
  end
end