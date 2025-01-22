module Api
  module V3
    # NOTE: a lot of logic in this controller should not be here. One day this
    # should be updated
    class ScenarioUsersController < BaseController
      include UsesScenario

      # Only scenario owners, having the delete authority, may manage scenario users
      before_action { authorize!(:destroy, @scenario) }

      def index
        render json: @scenario.scenario_users
      end

      # Creates all new ScenarioUsers provided
      def create
        process_scenario_users(create_new: true) do |scenario_user, _|
          unless scenario_user.valid?
            add_error(scenario_user.email, scenario_user.errors.messages.keys)
            next
          end

          begin
            scenario_user.save!
          rescue ActiveRecord::RecordNotUnique
            add_error(scenario_user.email, ['duplicate'])
            next
          end

          scenario_user
        end

        json_response(ok_status: :created, extra_condition: @scenario.save)
      end

      # Updates all ScenarioUsers provided
      def update
        process_scenario_users do |scenario_user, new_role|
          scenario_user.update_role(new_role)

          unless scenario_user.save
            add_error(scenario_user.email, scenario_user.errors.messages.keys)
            next
          end

          scenario_user
        end

        json_response
      end

      # Destroys all ScenarioUsers provided
      def destroy
        process_scenario_users do |scenario_user, _|
          unless scenario_user.destroy
            add_error(scenario_user.email, scenario_user.errors.messages.keys)
            next
          end

          scenario_user
        end

        json_response
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

      # Used as a block to create or find the ScenarioUsers from the params.
      # Yields the ScenarioUser and their new role.
      # Returns an array of succesfully processed records.
      def process_scenario_users(create_new: false)
        @succesful_records = scenario_user_params.filter_map do |user_params|
          scenario_user = if create_new
            new_scenario_user_from(user_params)
          else
            find_scenario_user_by_params(user_params)
          end

          next unless scenario_user

          yield(scenario_user, user_params[:role]&.to_sym)
        end
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

      # Create a new ScenarioUser record from given user_params
      def new_scenario_user_from(scenario_user_params)
        ScenarioUser.new(
          scenario: @scenario,
          role_id: User::ROLES.key(scenario_user_params[:role]&.to_sym),
          user_email: scenario_user_params[:user_email]
        )
      end

      def errors
        @errors ||= {}
      end

      # Adds an error for returning in the jsons.
      # Only allows one error on the record
      def add_error(scenario_user_key, message)
        errors[scenario_user_key] = message
      end

      def add_not_found_error(user_params)
        add_error(
          user_params[:id] || user_params[:user_id] || user_params[:user_email],
          ['Scenario user not found']
        )
      end

      def invite?
        permitted_params.dig(:invitation_args, :invite) == true
      end

      def json_response(ok_status: :ok, extra_condition: true)
        if errors.empty? && extra_condition
          render json: @succesful_records, status: ok_status
        else
          render json: { success: @succesful_records, errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end
end
