# frozen_string_literal: true

class Identity::TokenComponent < ApplicationComponent
  include ButtonHelper
  include Turbo::FramesHelper

  # TODO: Move this to a proper token generator class.
  TOKEN_PREFIX = Rails.env.staging? ? 'etm_beta_' : 'etm_'

  def initialize(token:)
    @token = token
    @access_token = token.oauth_access_token
    @show_full_token = @access_token.created_at > 1.minute.ago
  end

  def token_string
    token = @access_token.plaintext_token.to_s

    return token if @show_full_token

    if token.start_with?(TOKEN_PREFIX)
      "#{TOKEN_PREFIX}#{token.delete_prefix(TOKEN_PREFIX)[0..4]}..."
    else
      "#{token[0..4]}..."
    end
  end
end
