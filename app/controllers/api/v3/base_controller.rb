module Api
  module V3
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      rescue_from ActionController::ParameterMissing do |e|
        render status: 400, json: { errors: ["param is missing or the value is empty: #{e.param}"] }
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        if e.model
          render_not_found(errors: ["#{e.model.underscore.humanize} not found"])
        else
          render_not_found
        end
      end

      rescue_from ActiveModel::RangeError do
        render_not_found
      end

      rescue_from CanCan::AccessDenied do |e|
        if e.subject.is_a?(Scenario) && !e.subject.private?
          render status: :forbidden, json: { errors: ['Scenario does not belong to you'] }
        else
          render_not_found
        end
      end

      private

      def current_ability
        @current_ability ||=
          if current_user
            TokenAbility.new(doorkeeper_token, current_user)
          else
            GuestAbility.new
          end
      end

      def current_user
        @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
      end

      # Many API actions require an active scenario. Let's set it here
      # and let's prepare the field for the calculations.
      #
      def set_current_scenario
        @scenario = if params[:scenario_id]
          Scenario.find(params[:scenario_id])
        else
          Scenario.last
        end
      end

      # Send a 404 response with an optional JSON body.
      def render_not_found(body = { errors: ['Not found'] })
        render json: body, status: :not_found
      end

      # Processes the controller action.
      #
      # Wraps around the default to rescue malformed params (e.g. JSON bodies)
      # which is currently not possible with `rescue_from`.
      #
      # See: https://github.com/rails/rails/issues/38285
      def process_action(*args)
        super
      rescue ActionDispatch::Http::Parameters::ParseError => e
        render status: 400, json: { errors: [e.message] }
      end

      def doorkeeper_unauthorized_render_options(error:)
        { json: { errors: [error.description] } }
      end

      def doorkeeper_forbidden_render_options(error:)
        { json: { errors: [error.description] } }
      end
    end
  end
end
