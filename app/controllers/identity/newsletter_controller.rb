# frozen_string_literal: true

module Identity
  class NewsletterController < ApplicationController
    include IdentityController

    before_action :require_mailchimp_configured

    def edit
      return redirect_to(identity_profile_path) unless turbo_frame_request?
    end

    def update
      @subscribed = ActiveModel::Type::Boolean.new.cast(params[:subscribed])

      service = if @subscribed
        CreateNewsletterSubscription
      else
        DeleteNewsletterSubscription
      end

      service.new.call(user: current_user).either(
        lambda do |_|
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to(identity_profile_path) }
          end
        end,
        lambda do |error|
          Sentry.capture_exception(error)
          redirect_to(identity_profile_path)
        end
      )
    end

    private

    def require_mailchimp_configured
      redirect_to(identity_profile_path) unless ETEngine::Mailchimp.enabled?
    end
  end
end
