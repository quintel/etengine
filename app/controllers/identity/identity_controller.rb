# frozen_string_literal: true

module Identity
  module IdentityController
    extend ActiveSupport::Concern

    included do
      layout 'identity'
      before_action :authenticate_user!
    end

    private

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
