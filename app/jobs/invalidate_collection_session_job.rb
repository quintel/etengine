# frozen_string_literal: true

# Tells Collections that a session changed, so it drops its cached copy and refreshes any queries
class InvalidateCollectionSessionJob < ApplicationJob

  queue_as :collections

  OPEN_TIMEOUT = 1
  READ_TIMEOUT = 2

  def perform(session)
    url = Settings.collections_invalidate_url
    return if url.blank?

    client.post("#{url}/#{session.id}", payload(session), 'Content-Type' => 'application/json')
  rescue Faraday::Error => e
    Rails.logger.warn("Collections invalidation failed for session #{session.id}: #{e.message}")
  end

  private

  def client
    Faraday.new(request: { open_timeout: OPEN_TIMEOUT, timeout: READ_TIMEOUT })
  end

  def payload(session)
    { stamp: session.updated_at.utc.iso8601(6) }.to_json
  end
end
