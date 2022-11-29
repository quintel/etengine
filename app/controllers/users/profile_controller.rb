# frozen_string_literal: true

module Users
  class ProfileController < DeviseController
    layout 'identity'

    before_action :authenticate_user!

    def edit
      redirect_to user_profile_path
    end

    def edit_name
      @user = current_user
    end

    def update_name
      update_params = params.require(:user).permit(:name)

      # Fetch a new record so that we're not updating the current user in place.
      @user = User.find(current_user.id)

      if @user.update(update_params)
        redirect_to(user_profile_path, notice: {
          title: 'Name changed',
          message: 'The name of your account was successfully updated.'
        })
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

        redirect_to(user_profile_path, notice: {
          title: 'E-mail changed',
          message: 'Please check your inbox to confirm the change of e-mail address.'
        })
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

        redirect_to(user_profile_path, notice: {
          title: 'Password changed',
          message: 'Your password was successfully updated.'
        })
      else
        render(:edit_password, status: :unprocessable_entity)
      end
    end
  end
end
