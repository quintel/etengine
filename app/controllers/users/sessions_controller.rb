# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      super do
        if resource.legacy_password_salt
          migrate_legacy_password(resource, params.require(:user).require(:password))
        end

        if session['user_return_to'].to_s.start_with?('/oauth/authorize') && is_flashing_format?
          # Don't show the flash message when redirecting to an OAuth action.
          flash.delete(:notice)
        end
      end
    end

    def destroy
      super do
        # TODO: Add logout_urls to the application and validate that the URL is permitted.
        if params[:return_to].present?
          # Don't set a flash when redirecting back to a client application.
          flash.delete(:notice) if is_flashing_format?
          return redirect_to(params[:return_to], allow_other_host: true)
        end

        # Turbo requires redirects be :see_other (303); so override Devise default (302)
        return redirect_to(
          after_sign_out_path_for(resource_name),
          status: :see_other, allow_other_host: true
        )
      end
    end

    private

    # Migrate a user to the new password hashing scheme.
    def migrate_legacy_password(resource, password)
      resource.skip_password_change_notification!

      resource.update_with_password(
        password:,
        legacy_password_salt: nil,
        current_password: password
      )

      bypass_sign_in(resource)
    end

    def after_sign_out_path_for(...)
      Settings.auth.default_sign_out_url.presence || super
    end
  end
end
