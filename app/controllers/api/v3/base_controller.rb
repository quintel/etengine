# frozen_string_literal: true

module Api
  module V3
    class BaseController < ActionController::API
      include ActionController::MimeResponds
      include Identity::ResourceServer

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

      def set_current_scenario
        @scenario = if params[:scenario_id]
          Scenario.find(params[:scenario_id])
        else
          Scenario.last
        end
      end

      def process_action(*args)
        super
      rescue ActionController::BadRequest, ActionDispatch::Http::Parameters::ParseError => e
        render status: :bad_request, json: { errors: [e.message] }
      end

      private

      # Returns the current user, if a token is set and is valid.
      def current_user
        return nil unless decoded_token

        @current_user ||= User.from_jwt!(decoded_token)
      end

      def current_ability
        @current_ability ||=
          if current_user
            TokenAbility.new(decoded_token, current_user)
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
          conn.response(:json)
          conn.response(:raise_error)
          conn.request(:json)

          if (auth_header = request.authorization.to_s[/\ABearer (.+)\z/, 1])
            conn.request(:authorization, 'Bearer', auth_header)
          end
        end
      end
    end
  end
end
