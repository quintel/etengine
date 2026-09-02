# frozen_string_literal: true

# Triggers a webhook on Collections to clear all caches for the given session
# and refresh any queries
class InvalidateCollectionSessionJob < ApplicationJob
  queue_as :default
  # TODO: default now performs inline, but this is not optimal. Need a new queue type,
  # to perform after update request finished - or that is more async.

  def perform(session)
    InvalidateCollectionSessionJob.client.post(
      "#{Settings.hooks.collections.session}/#{session.id}"
    ) do |request|
      request.headers['Content-Type'] = 'application/json'
      request.body = { stamp: session.updated_at.utc.iso8601(6) }.to_json
    end
  end

  def self.client
    Faraday.new(url: Settings.hooks.collections.base_url)
  end
end
