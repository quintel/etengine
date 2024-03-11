module Api
  module V3
    class ScenarioUsersController < BaseController
      include UsesScenario

      respond_to :json

      # Only scenario owners, having the delete authority, may manage scenario users
      before_action { doorkeeper_authorize!(:'scenarios:delete') }

      def index
        render json: @scenario.scenario_users
      end

      # Creates all new ScenarioUsers provided
      def create
        new_users = scenario_user_params.filter_map do |scenario_user_params|
          scenario_user = new_scenario_user_from(scenario_user_params)

          unless scenario_user.valid?
            add_error(scenario_user.email, scenario_user.errors.full_messages)
            next
          end

          begin
            scenario_user.save!
          rescue ActiveRecord::RecordNotUnique
            add_error(scenario_user.email, ['duplicate'])
            next
          end

          # Send an email invitation to the added user
          send_invitation_mail_for(scenario_user) if invite?

          scenario_user
        end

        if errors.empty? && @scenario.save
          render json: new_users, status: :created
        else
          render json: { success: new_users, errors: errors }, status: :unprocessable_entity
        end
      end

      # Updates all new ScenarioUsers provided
      def update
        updated_users = scenario_user_params.filter_map do |user_params|
          scenario_user = find_scenario_user_by_params(user_params)

          next unless scenario_user

          scenario_user.update_role(user_params[:role]&.to_sym)

          unless scenario_user.save
            add_error(scenario_user.email, scenario_user.errors.full_messages)
            next
          end

          scenario_user
        end

        if errors.empty?
          render json: updated_users, status: :ok
        else
          render json: { success: updated_users, errors: errors }, status: :unprocessable_entity
        end
      end

      def destroy
        destroyed_users = scenario_user_params.filter_map do |user_params|
          scenario_user = find_scenario_user_by_params(user_params)

          next unless scenario_user

          unless scenario_user.destroy
            add_error(scenario_user.email, scenario_user.errors.full_messages)
            next
          end

          scenario_user
        end

        if errors.empty?
          render json: destroyed_users, status: :ok
        else
          render json: { success: destroyed_users, errors: errors }, status: :unprocessable_entity
        end
      end

      private

      def scenario_user_params
        permitted_params[:scenario_users]
      end

      def permitted_params
        params.permit(
          :scenario_id,
          scenario_users: [%i[id role user_id user_email invite]],
          invitation_args: %i[invite user_name id title]
        )
      end

      def invite?
        permitted_params.dig(:invitation_args, :invite) == true
      end

      # Find an existing ScenarioUser record by given user_params
      def find_scenario_user_by_params(user_params)
        scenario_user = nil

        if user_params[:id]&.present?
          scenario_user = @scenario.scenario_users.find(user_params[:id])
        elsif user_params[:user_id]&.present?
          scenario_user = @scenario.scenario_users.find_by(user_id: user_params[:user_id])
        elsif user_params[:user_email]&.present?
          scenario_user = @scenario.scenario_users.find_by(user_email: user_params[:user_email])

          # It may have happened the ScenarioUser is already coupled to a User.
          # Search all users for this email, then search for the found ID.
          if scenario_user.blank?
            user = User.find_by(email: user_params[:user_email])

            scenario_user = @scenario.scenario_users.find_by(user_id: user.id) if user.present?
          end
        end

        add_not_found_error(user_params) unless scenario_user

        scenario_user
      end

      def errors
        @errors ||= {}
      end

      # TODO: make it so we can add more errors on the same user, not overwrite
      def add_error(scenario_user_key, message)
        errors[scenario_user_key] = message
      end

      def add_not_found_error(user_params)
        add_error(
          user_params[:id] || user_params[:user_id] || user_params[:user_email],
          ['Scenario user not found']
        )
      end

      # Create a new ScenarioUser record from given user_params
      def new_scenario_user_from(scenario_user_params)
        ScenarioUser.new(
          scenario: @scenario,
          role_id: User::ROLES.key(scenario_user_params[:role]&.to_sym),
          user_email: scenario_user_params[:user_email]
        )
      end

      # Make sure a user knows it was added to a scenario by sending an email notifying them.
      def send_invitation_mail_for(scenario_user)
        if scenario_user.user_id.present?
          user_type = 'existing'
          email = scenario_user.user.email
        else
          user_type = 'new'
          email = scenario_user.user_email
        end

        ScenarioInvitationMailer.invite_user(
          user_type,
          email,
          permitted_params[:invitation_args][:user_name],
          permitted_params[:invitation_args].slice(:id, :title)
        )
      end
    end
  end
end
