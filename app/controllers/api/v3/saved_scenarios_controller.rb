# frozen_string_literal: true

module Api
  module V3
    class SavedScenariosController < BaseController
      render json:

      before_action(only: %i[index show]) do
        authorize!(:read, @scenario)
      end

      before_action(only: %i[create update]) do
        authorize!(:write, @scenario)
      end

      before_action(only: %i[discard undiscard]) do
        authorize!(:destroy, @scenario)
      end

      def index
        query = { page: params[:page], limit: params[:limit] }.compact.to_query
        response = ETEngine::Clients.idp_client.get("/api/v1/saved_scenarios?#{query}")

        render json: response.body.to_h.merge(
          'data'  => hydrate_scenarios(response.body['data']),
          'links' => update_pagination_links(response.body['links'])
        )
      end

      def show
        response = ETEngine::Clients.idp_client.get("/api/v1/saved_scenarios/#{params.require(:id).to_i}")
        render json: hydrate_scenario(response.body)
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      def create
        CreateSavedScenario.new.call(
          params: params.permit!.to_h,
          ability: current_ability,
          client: ETEngine::Clients.idp_client
        ).either(
          ->((data, *)) { render json: hydrate_scenario(data) },
          ->(errors)    { service_error_response(errors) }
        )
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      def update
        UpdateSavedScenario.new.call(
          id: params.require(:id),
          params: params.permit!.to_h,
          ability: current_ability,
          client: ETEngine::Clients.idp_client
        ).either(
          ->((data, *)) { render json: hydrate_scenario(data) },
          ->(error)     { service_error_response(error) }
        )
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      def destroy
        DeleteSavedScenario.new.call(
          id: params.require(:id),
          client: ETEngine::Clients.idp_client
        ).either(
          ->((data, *)) { render json: data },
          ->(error)     { service_error_response(error) }
        )
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      private

      def hydrate_scenarios(saved_scenarios)
        scenarios = Scenario
          .accessible_by(current_ability)
          .where(id: saved_scenarios.map { |s| s['scenario_id'] })
          .includes(:scaler, :users)
          .index_by(&:id)

        saved_scenarios.map do |saved_scenario|
          scenario   = scenarios[saved_scenario['scenario_id']]
          serialized = scenario ? ScenarioSerializer.new(self, scenario).as_json : nil

          saved_scenario[:scenario] = serialized
          saved_scenario
        end
      end

      def hydrate_scenario(saved_scenario)
        hydrate_scenarios([saved_scenario]).first
      end

      def update_pagination_links(links)
        request_uri = URI.parse(request.url)

        links.transform_values do |link|
          next unless link

          parsed = URI.parse(link)

          new_uri = request_uri.dup
          new_uri.query = parsed.query
          new_uri.to_s
        end
      end

      def saved_scenario_params
        params.permit(:scenario_id, :title, :description, :private)
      end

      def service_error_response(failure)
        if failure.respond_to?(:to_response)
          render failure.to_response
        else
          render json: { errors: failure }, status: :unprocessable_entity
        end
      end
    end
  end
end
