# frozen_string_literal: true

module Api
  module V3
    # Updates user information.
    class UserController < BaseController
      before_action :authorize_user!, only: :update

      def update
        if user.update(name: params.require(:name))
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

      def user
        @user ||= current_user
      end

      def authorize_user!
        head(:forbidden) if user.id != params.require(:id).to_i
      end
    end
  end
end
