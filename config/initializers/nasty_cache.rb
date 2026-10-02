# frozen_string_literal: true

# An ETSource import expires the NastyCache in the process which handled it, and broadcasts the
# expiry to the others through Rails.cache. Checking for that broadcast on each unit of work -- and
# not in an ApplicationController callback -- means every process picks the new revision up on its
# next request, including requests served by the API controllers, which descend from
# ActionController::API and run no ApplicationController callbacks.
Rails.application.executor.to_run do
  NastyCache.instance.initialize_request
end
