# frozen_string_literal: true

module Api
  module V3
    # Updates user information.
    class UsersController < BaseController

      def update
        if user.update(user_params)
          render json: user
        else
          render json: user.errors, status: :unprocessable_entity
        end
      end

      def destroy
        user.destroy
        head :ok
      end

      private

      def user_params
        params.require(:user).permit(:name, :private_scenarios)
      end

      def user
        @user ||= current_user
      end
    end
  end
end
