module Api
  module V3
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      before_action :authenticate_request!

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

      def authenticate_request!
        unless decoded_token
          Rails.logger.warn "Unauthorized: No valid token provided"
          render json: { errors: ['Unauthorized'] }, status: :unauthorized
          return
        end

        unless current_user
          Rails.logger.warn "Unauthorized: No user found for token"
          render json: { errors: ['Unauthorized'] }, status: :unauthorized
        end
      end

      def decoded_token
        return @decoded_token if defined?(@decoded_token)

        auth_header = request.headers['Authorization']
        token = auth_header.split(' ').last if auth_header
        return unless token

        @decoded_token = ETEngine::TokenDecoder.decode(token)
      rescue ETEngine::TokenDecoder::DecodeError => e
        Rails.logger.error "Token decoding failed: #{e.message}"
        nil
      end

      def current_user
        return @current_user if defined?(@current_user)

        if decoded_token
          user_data = decoded_token[:user]
          @current_user = User.find_or_initialize_by(id: decoded_token[:sub])
          @current_user.assign_attributes(user_data)
        else
          Rails.logger.debug "No valid token; cannot find user"
        end

        @current_user
      end

      def current_ability
        @current_ability ||= @current_user ? TokenAbility.new(decoded_token, @current_user) : GuestAbility.new
      end

      def render_not_found(body = { errors: ['Not found'] })
        render json: body, status: :not_found
      end
    end
  end
end
