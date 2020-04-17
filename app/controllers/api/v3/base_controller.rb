module Api
  module V3
    class BaseController < ApplicationController
      rescue_from ActionController::ParameterMissing do |e|
        render status: 400, json: { errors: [e.message] }
      end

      private

      # Many API actions require an active scenario. Let's set it here
      # and let's prepare the field for the calculations.
      #
      def set_current_scenario
        @scenario = if params[:scenario_id]
          Scenario.find(params[:scenario_id])
        else
          Scenario.last
        end
      rescue ActiveRecord::RecordNotFound
        render :json => {:errors => ["Scenario not found"]}, :status => 404 and return
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
