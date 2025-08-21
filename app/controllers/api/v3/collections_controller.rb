# frozen_string_literal: true

module Api
  module V3
    class CollectionsController < BaseController
      before_action :warn_if_deprecated

      before_action(only: %i[index show]) do
        authorize!(:read, Scenario)
      end

      before_action(only: %i[create update]) do
        authorize!(:write, Scenario)
      end

      before_action(only: %i[destroy]) do
        authorize!(:destroy, Scenario)
      end

      def index
        query = { page: params[:page], limit: params[:limit] }.compact.to_query
        response = my_etm_client.get("/api/v1/collections?#{query}")

        render json: response.body.to_h.merge(
          'data'  => response.body['data'],
          'links' => update_pagination_links(response.body['links'])
        )
      end

      def show
        response = my_etm_client.get("/api/v1/collections/#{params.require(:id).to_i}")
        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      def create
        UpsertTransitionPath.new(
          endpoint_path: '/api/v1/collections',
          method: :post
        ).call(
          params: params.permit!.to_h.merge(version: Settings.version_tag),
          ability: current_ability,
          client: my_etm_client
        ).either(
          ->((data, *)) { render json: data },
          ->(errors)    { service_error_response(errors) }
        )
      end

      def update
        UpsertTransitionPath.new(
          endpoint_path: "/api/v1/collections/#{params.require(:id).to_i}",
          method: :put
        ).call(
          params: params.permit!.to_h,
          ability: current_ability,
          client: my_etm_client
        ).either(
          ->((data, *)) { render json: data },
          ->(error)     { service_error_response(error) }
        )
      end

      def destroy
        response = my_etm_client.delete("/api/v1/collections/#{params.require(:id).to_i}")
        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      private

      def update_pagination_links(links)
        return {} unless links.is_a?(Hash)

        request_uri = URI.parse(request.url)

        links.transform_values do |link|
          next unless link

          parsed = URI.parse(link)

          new_uri = request_uri.dup
          new_uri.query = parsed.query
          new_uri.to_s
        end
      end

      def service_error_response(failure)
        if failure.respond_to?(:to_response)
          render failure.to_response
        else
          render json: { errors: failure }, status: :unprocessable_content
        end
      end

      # Deprecation warning for users accessing collections via the transition paths endpoint
      def warn_if_deprecated
        if request.path.match?(%r{/transition_paths})
          response.set_header('Deprecation-Notice', 'transition_paths is deprecated; use /collections instead.')
          Rails.logger.warn('Deprecation: transition_paths endpoint called instead of collections')
        end
      end
    end
  end
end
