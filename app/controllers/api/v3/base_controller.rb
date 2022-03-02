module Api
  module V3
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token

      rescue_from ActionController::ParameterMissing do |e|
        render status: 400, json: { errors: ["param is missing or the value is empty: #{e.param}"] }
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        if e.model
          render_not_found(errors: ["#{e.model.underscore.humanize} not found"])
        else
          render_not_found(errors: ['Not found'])
        end
      end

      rescue_from ActiveModel::RangeError do
        render_not_found(errors: ['Not found'])
      end

      rescue_from CanCan::AccessDenied do |ex|
        if (request.post? || request.put? || request.delete?) &&
            ex.subject.is_a?(Scenario) && ex.subject.protected?
          render status: 403, json: { errors: ['Cannot modify a protected scenario'] }
        else
          render status: 404, json: { errors: ['Not found'] }
        end
      end

      private

      def current_ability
        @current_ability ||= Api::Ability.new(current_user)
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
      def render_not_found(body = {})
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
    end
  end
end
