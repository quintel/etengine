# frozen_string_literal: true

# Records when a personal access token was used.
class TrackPersonalAccessTokenUse < ApplicationJob
  queue_as :default

  def perform(token_id, time)
    token = PersonalAccessToken.find_by(oauth_access_token_id: token_id)

    return unless token

    token.update(last_used_at: time) if token.last_used_at.nil? || token.last_used_at < time
  end
end
