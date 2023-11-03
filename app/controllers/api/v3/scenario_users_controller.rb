module Api
  module V3
    # Allows owners of a Scenario to manage the roles for users on a given scenario
    class ScenarioUsersController < BaseController
      respond_to :json

      check_authorization

      authorize_resource class: Scenario

      before_action :find_scenario, except: :index

      def index
        render json: users_return_values
      end

      def create
        render json: users_return_values and return if scenario_params[:users].blank?

        scenario_params[:users].each do |user_params|
          @scenario.scenario_users << build_scenario_user(user_params)
        end

        if @scenario.save
          render json: users_return_values, status: :created
        else
          render json: scenario.errors, status: :unprocessable_entity
        end
      end

      def update
        render json: users_return_values and return if scenario_params[:users].blank?

        scenario_users_updated = true
        scenario_user_error = nil
        http_error_status = :unprocessable_entity

        scenario_params[:users].each do |user_params|
          su = @scenario.scenario_users.find_by(
            user_id: user_params.try(:[], :id)
          )

          if su.blank?
            scenario_users_updated = false
            http_error_status = :not_found

            break
          end

          unless (scenario_users_updated = su.update(role_id: User::ROLES.key(user_params.try(:[], :role).to_sym)))
            scenario_user_error = su.errors

            break
          end
        end

        if scenario_users_updated
          render json: users_return_values, status: :ok
        else
          render json: scenario_user_error, status: http_error_status
        end
      end

      def destroy
        render json: users_return_values and return if scenario_params[:user_ids].blank?

        @scenario.scenario_users.where(
          user_id: scenario_params[:user_ids]
        ).destroy_all

        head :ok
      end

      private

      def scenario_params
        params.permit(:scenario_id, users: [%i[id role email]], user_ids: [])
      end

      def find_scenario
        @scenario = current_user.scenarios.find(scenario_params[:scenario_id])
      end

      def users_return_values
        user_ids = scenario_params[:users].pluck(:id) if scenario_params[:users].present?

        scenario_users = @scenario.scenario_users
        scenario_users = scenario_users.where(user_id: user_ids) if user_ids.present?

        scenario_users.map do |u|
          { id: u.user_id, email: u.user_email, role: User::ROLES[u.role_id] }
        end
      end

      def build_scenario_user(user_params)
        user = User.find_by(email: user_params.try(:[], :email))

        ScenarioUser.new(
          user_id: user_params.try(:[], :id),
          scenario_id: scenario_params[:scenario_id],
          role_id: User::ROLES.key(user_params.try(:[], :role).to_sym),
          user_email: user.present? ? nil : user_params.try(:[], :email)
        )
      end
    end
  end
end

