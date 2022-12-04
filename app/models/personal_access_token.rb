# frozen_string_literal: true

class PersonalAccessToken < ApplicationRecord
  include Doorkeeper::Models::ExpirationTimeSqlMath

  TOKEN_PREFIX = Rails.env.staging? ? 'etm_beta_' : 'etm_'

  belongs_to :user
  belongs_to :oauth_access_token, class_name: 'Doorkeeper::AccessToken', dependent: :destroy

  validates :name, presence: true

  def self.not_expired
    relation = joins(:oauth_access_token)
      .includes(:oauth_access_token)
      .where(oauth_access_tokens: { revoked_at: nil })

    relation
      .where("#{Doorkeeper::AccessToken.expiration_time_sql} > ?", Time.now.utc)
      .or(relation.where(oauth_access_tokens: { expires_in: nil }))
  end
end
