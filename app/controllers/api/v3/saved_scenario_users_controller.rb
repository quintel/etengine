# frozen_string_literal: true

module Api
  module V3
    class SavedScenarioUsersController < BaseController
      before_action do
        authorize!(:update, Scenario)
      end

      def index
        response = my_etm_client.get(
          "/api/v1/saved_scenarios/#{params[:saved_scenario_id]}/users"
        )

        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      rescue Faraday::Error => e
        handle_faraday_error(e)
      end

      def create
        response = my_etm_client.post(
          "/api/v1/saved_scenarios/#{params[:saved_scenario_id]}/users",
          users_payload
        )

        render json: response.body, status: :created
      rescue Faraday::ResourceNotFound
        render_not_found
      rescue Faraday::Error => e
        handle_faraday_error(e)
      end

      def update
        response = my_etm_client.put(
          "/api/v1/saved_scenarios/#{params[:saved_scenario_id]}/users",
          users_payload
        )

        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      rescue Faraday::Error => e
        handle_faraday_error(e)
      end

      def destroy
        response = my_etm_client.delete(
          "/api/v1/saved_scenarios/#{params[:saved_scenario_id]}/users"
        ) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = users_payload.to_json
        end

        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      rescue Faraday::Error => e
        handle_faraday_error(e)
      end

      private

      def users_payload
        users = params.permit(
          saved_scenario_users: %i[id role user_id user_email]
        )[:saved_scenario_users]

        {
          saved_scenario_users: users&.map(&:to_h) || []
        }
      end

      def handle_faraday_error(error)
        if error.response
          status = error.response[:status]
          body = error.response[:body]

          render json: body, status:
        else
          render json: { errors: ['Failed to connect to MyETM'] },
            status: :service_unavailable
        end
      end
    end
  end
end
