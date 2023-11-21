module Api
  module V3
    class ScenarioUsersController < BaseController
      respond_to :json

      before_action { doorkeeper_authorize!(:'scenarios:delete') }

      before_action :find_and_authorize_scenario

      before_action :validate_users_presence, only: %i[create update destroy]

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

          # Send an invitation if stated in the params
          if permitted_params.dig(:invitation_args, :invite) == true
            send_invitation_mail(scenario_user)
          end
        end

        if @scenario.save
          render json: users_return_values, status: :created
        else
          render json: @scenario.errors, status: :unprocessable_entity
        end
      end

      def update
        scenario_user_error = nil
        http_error_status = :unprocessable_entity

        permitted_params[:scenario_users].each do |user_params|
          if user_params.try(:[], :role).blank?
            scenario_user_error = user_params.merge({ error: 'No role given to update with.' })

            break
          end

          if user_params.try(:[], :id).present?
            su = @scenario.scenario_users.find_by(user_id: user_params.try(:[], :id))
          elsif user_params.try(:[], :email).present?
            su = @scenario.scenario_users.find_by(user_email: user_params.try(:[], :email))

            # Maybe the 'nameless' user got converted to actual user already. Search for them
            if su.blank?
              user = User.find_by(email: user_params.try(:[], :email))

              if user.present?
                su = @scenario.scenario_users.find_by(user_id: user.id)
              end
            end
          end

          if su.blank?
            scenario_user_error = user_params.merge({ error: 'Scenario user not found' })
            http_error_status = :not_found

            break
          end

          unless (scenario_users_updated = su.update(role_id: User::ROLES.key(user_params.try(:[], :role).try(:to_sym))))
            scenario_user_error = su.errors

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
        param_user_ids = permitted_params[:scenario_users].pluck(:id).compact.uniq
        param_user_emails = permitted_params[:scenario_users].pluck(:email).compact.uniq
        user_ids = User.where(email: param_user_emails).pluck(:id)

        scenario_users = @scenario.scenario_users.where(
          'user_id IN (?) OR user_id IN (?) OR user_email IN (?)',
          user_ids, param_user_ids, param_user_emails
        )

        # If we found less users than requested, we either:
        # a) Could not find one of the requested users, or
        # b) There are duplicate entries in the request that we filtered out
        if scenario_users.count < permitted_params[:scenario_users].length
          diff = (param_user_ids + param_user_emails) - scenario_users.pluck(:user_id)

          if diff.present?
            render json: { error: "Could not find user(s) with id: #{diff.join(',')}" }, status: :not_found
          else
            render json: { error: "Duplicate user ids found in request, please revise." }, status: :unprocessable_entity
          end

          return
        end

        scenario_users.destroy_all

        head :ok
      end

      private

      def permitted_params
        params.permit(:scenario_id, scenario_users: [%i[id role email invite]], invitation_args: %i[invite user_name id title])
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

      def validate_users_presence
        return true if permitted_params[:scenario_users].present?

        render json: { error: 'No users given to perform action on.' }, status: :unprocessable_entity

        return false
      end

      def users_return_values
        user_ids = permitted_params[:scenario_users].pluck(:id) if permitted_params[:scenario_users].present?

        scenario_users = @scenario.scenario_users
        scenario_users = scenario_users.where(user_id: user_ids) if user_ids.present?

        scenario_users.map do |u|
          { id: u.user_id, email: u.user_email, role: User::ROLES[u.role_id] }
        end
      end

      def new_scenario_user_from(user_params)
        user = User.find_by(email: user_params.try(:[], :email))

        ScenarioUser.new(
          scenario: @scenario,
          role_id: User::ROLES.key(user_params.try(:[], :role).try(:to_sym)),
          user_id: user.present? ? user.id : user_params.try(:[], :id),
          user_email: user.present? ? nil : user_params.try(:[], :email)
        )
      end

      # Make sure a user knows it was added to a scenario by sending an email notifying them.
      def send_invitation_mail(scenario_user)
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

