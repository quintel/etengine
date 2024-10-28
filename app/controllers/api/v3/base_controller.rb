module Api
  module V3
    class BaseController < ActionController::API
      # include ActionController::MimeResponds

      # after_action :track_token_use
      rescue_from ActionController::ParameterMissing do |e|
        render json: { errors: [e.message] }, status: :bad_request
      end

      # rescue_from ActionController::ParameterMissing do |e|
      #   render status: 400, json: { errors: ["param is missing or the value is empty: #{e.param}"] }
      # end

      # rescue_from ActiveRecord::RecordNotFound do |e|
      #   if e.model
      #     render_not_found(errors: ["#{e.model.underscore.humanize} not found"])
      #   else
      #     render_not_found
      #   end
      # end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: {
          errors: ["No such #{e.model.underscore.humanize.downcase}: #{e.id}"]
        }, status: :not_found
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
# TODO: Update all of these to use JWTs instead of doorkeeper_token - at the moment doorkeeper_token = decoded_token, but this needs to be set up properly

      def current_ability
        @current_ability ||=
          if current_user
            TokenAbility.new(decoded_token, current_user)
          else
            GuestAbility.new
          end
      end

      def current_user
        @current_user ||= User.find(decoded_token.resource_owner_id) if decoded_token
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

      # def doorkeeper_unauthorized_render_options(error:)
      #   { json: { errors: [error.description] } }
      # end

      # def doorkeeper_forbidden_render_options(error:)
      #   { json: { errors: [error.description] } }
      # end

      # def track_token_use
      #   if response.status == 200 && decoded_token && decoded_token.application_id.nil?
      #     TrackPersonalAccessTokenUse.perform_later(decoded_token.id, Time.now.utc)
      #   end
      # end
    end
  end
end
