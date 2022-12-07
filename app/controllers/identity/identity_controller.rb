# frozen_string_literal: true

module Identity
  module IdentityController
    extend ActiveSupport::Concern

    included do
      layout 'identity'
      before_action :authenticate_user!
      before_action :set_back_url
    end

    private

    def set_back_url
      return unless params[:client_id]

      app = OAuthApplication.find_by(uid: params[:client_id])
      session[:back_to_etm_url] = app.uri if app&.uri && app&.first_party?
    end

    def turbo_notice(message = nil)
      if message.nil?
        message = flash[:notice]
        flash.delete(:notice)
      end

      return if message.nil?

      turbo_stream.update(
        'toast',
        ToastComponent.new(type: :notice, message:).render_in(view_context)
      )
    end
  end
end
