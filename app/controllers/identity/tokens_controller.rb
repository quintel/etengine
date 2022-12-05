# frozen_string_literal: true

module Identity
  class TokensController < ApplicationController
    include IdentityController

    def index
      tokens = current_user.personal_access_tokens.not_expired.order(:name)

      # Find a token created within the last minute and show it first.
      @tokens = tokens
        .partition { |token| token.oauth_access_token.created_at > 1.minute.ago }
        .flatten!
    end

    def new
      @token = CreatePersonalAccessToken::Params.new
    end

    def create
      result = CreatePersonalAccessToken.call(
        user: current_user,
        params: params[:create_personal_access_token_params].permit!
      )

      if result.failure?
        @token = result.failure
        render :new
      else
        Identity::TokenMailer.created_token(result.value!).deliver_later

        flash[:notice] = t('identity.tokens.created')
        redirect_to identity_tokens_path
      end
    end

    # Removes a personal access token by revoking it.
    #
    # DELETE /identity/tokens/:id
    def destroy
      token.oauth_access_token.update!(revoked_at: Time.now.utc)

      flash[:notice] = t('identity.tokens.revoked')

      respond_to do |format|
        format.html { redirect_to identity_tokens_path }

        format.turbo_stream do
          ui_action = if current_user.personal_access_tokens.not_expired.count.positive?
            turbo_stream.remove(token)
          else
            turbo_stream.replace(@token, partial: 'identity/tokens/empty_state')
          end

          render turbo_stream: [ui_action, turbo_notice]
        end
      end
    end

    private

    def token
      @token ||= current_user.personal_access_tokens.find(params[:id])
    end
  end
end
