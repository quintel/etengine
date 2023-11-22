module Api
  module V3
    class ScenarioUsersController < BaseController
      respond_to :json

      # Only scenario owners, having the delete authority, may manage scenario users
      before_action { doorkeeper_authorize!(:'scenarios:delete') }

      before_action :find_and_authorize_scenario

      def index
        render json: users_return_values
      end

      def create
        permitted_params[:scenario_users].each do |user_params|
          scenario_user = new_scenario_user_from(user_params)

          begin
            scenario_user.save!
          rescue ActiveRecord::RecordInvalid
            render json: user_params.merge({ error: "#{scenario_user.errors.first&.attribute} is invalid." }),
              status: :unprocessable_entity and return
          rescue ActiveRecord::RecordNotUnique
            render json: user_params.merge({ error: 'A user with this ID or email already exists for this scenario' }),
              status: :unprocessable_entity and return
          end

          # Send an email invitation to the added user only if stated in the params
          if permitted_params.dig(:invitation_args, :invite) == true
            send_invitation_mail_for(scenario_user)
          end
        end

        if @scenario.save
          render json: users_return_values, status: :created
        else
          render json: @scenario.errors, status: :unprocessable_entity
        end
      end

      def update
        return unless validate_scenario_user_params(['role', ['id', 'user_id', 'user_email']])

        http_error_status, scenario_user_error = nil, nil

        permitted_params[:scenario_users].each do |user_params|
          # Find the user
          unless (scenario_user = find_scenario_user_by_params(user_params))
            scenario_user_error = user_params.merge({ error: 'Scenario user not found' })
            http_error_status = :not_found

            break
          end

          # Attempt to update the user
          unless scenario_user.update(role_id: User::ROLES.key(user_params[:role].to_sym))
            scenario_user_error = scenario_user.errors
            http_error_status = :unprocessable_entity

            break
          end
        end

        if scenario_user_error
          render json: scenario_user_error, status: http_error_status
        else
          render json: users_return_values, status: :ok
        end
      end

      def destroy
        return unless validate_scenario_user_params([['id', 'user_id', 'user_email']])

        # Find scenario_users by id, user_id, user_email,
        # or the id of users found through their email address indirectly
        scenario_users = @scenario.scenario_users.where(
          'id in (?) OR user_email IN (?) OR user_id IN (?) OR user_id IN (?)',
          permitted_params[:scenario_users].pluck('id'),
          permitted_params[:scenario_users].pluck('user_email'),
          permitted_params[:scenario_users].pluck('user_id'),
          User.where(email: permitted_params[:scenario_users].pluck('user_email')).pluck(:id)
        )

        scenario_users.destroy_all

        head :ok
      end

      private

      def permitted_params
        params.permit(
          :scenario_id,
          scenario_users: [%i[id role user_id user_email invite]],
          invitation_args: %i[invite user_name id title]
        )
      end

      def find_and_authorize_scenario
        if current_user.blank?
          render json: { error: "Saved scenario with id #{permitted_params[:scenario_id]} not found." }, status: :not_found

          return false
        end

        @scenario = \
          if current_user.admin?
            Scenario.find(permitted_params[:scenario_id])
          else
            current_user.scenarios.find(permitted_params[:scenario_id])
          end

        if @scenario.blank? || (@scenario.present? && !@scenario.owner?(current_user) && !current_user.admin?)
          render json: { error: "Saved scenario with id #{permitted_params[:scenario_id]} not found." }, status: :not_found

          return false
        end
      end

      def validate_scenario_user_params(attributes)
        if permitted_params[:scenario_users].blank?
          render json: { error: 'No users given to perform action on.' }, status: :unprocessable_entity

          return false
        end

        # Check if all scenario_users have the requested attributes
        permitted_params[:scenario_users].each do |user_params|
          attributes.each do |attribute|
            pp attribute

            # If this is an array of attributes, at least one of the entries should be present
            valid = \
              if attribute.is_a? Array
                (attribute - user_params.keys).length < attribute.length
              else
                user_params.keys.include?(attribute)
              end

            unless valid
              missing_attr = attribute.is_a?(Array) ? attribute.join(' or ') : attribute

              render json: user_params.merge({ error: "Missing attribute(s) for scenario_user: #{missing_attr}" }),
                status: :unprocessable_entity

              return false
            end
          end
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

          # It may have happened the user was registered through email but was saved by
          # its ID. Search all users for this email, then search for the found ID
          # through the users for this scenario just to be sure.
          if scenario_user.blank?
            user = User.find_by(email: user_params[:user_email])

            if user.present?
              scenario_user = @scenario.scenario_users.find_by(user_id: user.id)
            end
          end
        end

        scenario_user
      end

      # Format the return values for the users in the given scenario
      def users_return_values
        if permitted_params[:scenario_users].present?
          user_ids = permitted_params[:scenario_users].pluck(:user_id)
        end

        scenario_users = @scenario.scenario_users
        scenario_users = scenario_users.where(user_id: user_ids) if user_ids.present?

        scenario_users.map do |su|
          { id: su.id, user_id: su.user_id, user_email: su.user_email, role: User::ROLES[su.role_id] }
        end
      end

      # Create a new ScenarioUser record from given user_params
      def new_scenario_user_from(user_params)
        if user_params[:user_id].present?
          user = User.find(user_params[:user_id])
        elsif user_params[:user_email].present?
          user = User.find_by(email: user_params[:email])
        end

        ScenarioUser.new(
          scenario: @scenario,
          role_id: User::ROLES.key(user_params.try(:[], :role).try(:to_sym)),
          user_id: user&.id,
          user_email: user&.email || user_params.try(:[], :user_email)
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

