# frozen_string_literal: true

module Api
  module V3
    # Updates user information.
    class UserController < BaseController

      def update
        # Verify that the user being updated matches the user authorized by the token.
        return head(:forbidden) if current_user.id != params.require(:id).to_i

        if current_user.update(name: params.require(:name))
          render json: current_user
        else
          render json: current_user.errors, status: :unprocessable_entity
        end
      end

      def destroy
        current_user.destroy
        head :ok
      end
    end
  end
end
