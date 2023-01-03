# frozen_string_literal: true

# Creates a personal access token and OAuth token for a given user.
class CreatePersonalAccessToken
  # Parameters for creating a personal access token.
  class Params < Dry::Struct
    include ActiveModel::Validations
    extend ActiveModel::Translation

    SCOPES_PUBLIC = 'openid public'
    SCOPES_READ   = "#{SCOPES_PUBLIC} scenarios:read".freeze
    SCOPES_WRITE  = "#{SCOPES_READ} scenarios:write".freeze
    SCOPES_DELETE = "#{SCOPES_WRITE} scenarios:delete".freeze

    SCOPES = {
      public: SCOPES_PUBLIC,
      read:   SCOPES_READ,
      write:  SCOPES_WRITE,
      delete: SCOPES_DELETE
    }.freeze

    ExpiresType = Dry::Types['coercible.integer'] | Dry::Types['coercible.string']

    attribute :name,          Dry::Types['coercible.string'].default('')
    attribute :permissions,   Dry::Types['coercible.symbol'].default(:public)
    attribute :email_scope,   Dry::Types['params.bool'].default(false)
    attribute :profile_scope, Dry::Types['params.bool'].default(false)
    attribute :expires_in,    ExpiresType.default(30)

    transform_keys(&:to_sym)

    validates :name, presence: true
    validates :permissions, inclusion: { in: SCOPES.keys }
    validates :expires_in,
              numericality: { greater_than: 0, unless: :never_expires? },
              inclusion: { in: %w[never], message: :invalid, if: :never_expires? }

    def to_oauth_token_params
      {
        expires_in: never_expires? ? nil : expires_in.to_i.days,
        scopes:
      }
    end

    def to_key = nil

    private

    def scopes
      [
        SCOPES[permissions],
        email_scope ? 'email' : nil,
        profile_scope ? 'profile' : nil
      ].compact.join(' ')
    end

    def never_expires?
      expires_in == 'never'
    end
  end

  include Dry::Monads[:result]

  def self.call(user:, params:)
    new(user, Params.new(params)).call
  end

  def initialize(user, params)
    @user   = user
    @params = params
  end

  def call
    attempts ||= 0

    return Failure(@params) unless @params.valid?

    PersonalAccessToken.transaction do
      oauth_token = @user.access_tokens.create!(@params.to_oauth_token_params)

      # Add the token prefix to the token. We could create a custom generator, but _for now_
      # updating the token is easier.
      oauth_token.update!(token: "#{PersonalAccessToken::TOKEN_PREFIX}#{oauth_token.token}")

      token = @user.personal_access_tokens.create!(
        name: @params.name,
        oauth_access_token: oauth_token
      )

      Success(token)
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    attempts += 1

    # Retry if there was a collision on the token.
    attempts < 3 ? retry : raise(e)
  end
end
