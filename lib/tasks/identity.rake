# frozen_string_literal: true

namespace :identity do
  task scheduled: %i[trim_tokens notify_expiring_tokens]

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

  desc 'Notify users of soon-to-expire tokens'
  task notify_expiring_tokens: :environment do
    tokens = PersonalAccessToken
      .joins(:oauth_access_token)
      .where(<<~SQL.squish, { date: 3.days.from_now.beginning_of_day.utc })
        oauth_access_tokens.expires_in IS NOT NULL AND
        oauth_access_tokens.revoked_at IS NULL AND
          (DATE_ADD(oauth_access_tokens.created_at, INTERVAL oauth_access_tokens.expires_in SECOND) > :date AND
            DATE_ADD(oauth_access_tokens.created_at, INTERVAL oauth_access_tokens.expires_in SECOND) < DATE_ADD(:date, INTERVAL 1 DAY))
      SQL

    tokens.find_each do |token|
      puts "Expiring: #{token.inspect}"
      Identity::TokenMailer.expiring_token(token).deliver_later
    end
  end
end
