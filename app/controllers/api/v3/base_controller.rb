module Api
  module V3
    class BaseController < ApplicationController
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
    end
  end
end
