# frozen_string_literal: true

module Identity
  class SettingsController < ApplicationController
    include IdentityController

    def edit_name
      @user = current_user
    end

    def update_name
      update_params = params.require(:user).permit(:name)

      # Fetch a new record so that we're not updating the current user in place.
      @user = User.find(current_user.id)

      if @user.update(update_params)
        redirect_to(
          identity_profile_path,
          notice: I18n.t('identity.settings.update_name.success')
        )

        SyncUserJob.perform_later(@user.id)
      else
        render(:edit_name, status: :unprocessable_entity)
      end
    end

    def edit_email
      @user = current_user
    end

    def update_email
      update_params = params.require(:user).permit(:current_password, :email)

      # Fetch a new record so that we're not updating the current user in place.
      @user = User.find(current_user.id)

      if @user.update_with_password(update_params)
        bypass_sign_in(current_user)

        redirect_to(
          identity_profile_path,
          notice: I18n.t('identity.settings.update_email.success')
        )
      else
        render(:edit_email, status: :unprocessable_entity)
      end
    end

    def edit_password
      @user = current_user
    end

    def update_password
      password_params = params.require(:user).permit(:current_password, :password)

      # Fetch a new record so that we're not updating the current user in place.
      @user = User.find(current_user.id)

      if @user.update_with_password(password_params)
        bypass_sign_in(@user)

        redirect_to(
          identity_profile_path,
          notice: I18n.t('identity.settings.update_password.success')
        )
      else
        render(:edit_password, status: :unprocessable_entity)
      end
    end

    def update_scenario_privacy
      privacy_params = params.require(:user).permit(:private_scenarios)

      current_user.update(privacy_params)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to(identity_profile_path) }
      end
    end
  end
end
