module Api
  module V3
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      rescue_from ActionController::ParameterMissing do |e|
        render json: { errors: [e.message] }, status: :bad_request
      end

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

      rescue_from ETEngine::TokenDecoder::DecodeError do
        render json: { errors: ['Invalid or expired token'] }, status: :unauthorized
      end

      def set_current_scenario
        @scenario = if params[:scenario_id]
          Scenario.find(params[:scenario_id])
        else
          Scenario.last
        end
      end

      def process_action(*args)
        super
      rescue ActionDispatch::Http::Parameters::ParseError => e
        render status: 400, json: { errors: [e.message] }
      end

      private

      # Returns the contents of the current token, if an Authorization header is set.
      def token
        return @token if @token
        return nil if request.authorization.blank?

        request.authorization.to_s.match(/\ABearer (.+)\z/) do |match|
          return @token = ETEngine::TokenDecoder.decode(match[1])
        end
      end

      # Returns the current user, if a token is set and is valid.
      def current_user
        return nil unless token

        @current_user ||= User.from_jwt!(token) if token
      end

      def current_ability
        @current_ability ||=
          if current_user
            TokenAbility.new(token, current_user)
          else
            GuestAbility.new
          end
      end

      def render_not_found(body = { errors: ['Not found'] })
        render json: body, status: :not_found
      end

      # Returns the Faraday client which should be used to communicate with the MyETM API.
      # This reuses the authentication token from the current request.
      def my_etm_client
        Faraday.new(url: Settings.identity.issuer) do |conn|
          if (auth_header = request.authorization.to_s[/\ABearer (.+)\z/, 1])
            conn.headers['Authorization'] = "Bearer #{auth_header}"
          end
        end
      end
    end
  end
end
