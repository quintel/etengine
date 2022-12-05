# frozen_string_literal: true

namespace :identity do
  desc 'Clear our revoked and expired tokens'
  task trim_tokens: :environment do
    delete_before = (ENV['DOORKEEPER_DAYS_TRIM_THRESHOLD'] || 30).to_i.days.ago
    expire = [
      <<~SQL.squish, { delete_before: }
        (revoked_at IS NOT NULL AND revoked_at < :delete_before) OR
        (expires_in IS NOT NULL AND DATE_ADD(created_at, INTERVAL expires_in SECOND) < :delete_before)
      SQL
    ]

    Doorkeeper::AccessGrant.where(expire).in_batches(&:delete_all)

    Doorkeeper::AccessToken.where(expire).in_batches.each do |batch|
      # Delete any personal access tokens that are associated with the access tokens.
      PersonalAccessToken.where(oauth_access_token_id: batch.map(&:id)).in_batches(&:delete_all)

      batch.delete_all
    end
  end
end
