# frozen_string_literal: true

module Api
  module V3
    class TransitionPathsController < BaseController
      respond_to :json

      before_action(only: %i[index show])    { doorkeeper_authorize!(:'scenarios:read') }
      before_action(only: %i[create update]) { doorkeeper_authorize!(:'scenarios:write') }
      before_action(only: %i[destroy])       { doorkeeper_authorize!(:'scenarios:delete') }

      def index
        query = { page: params[:page], limit: params[:limit] }.compact.to_query
        response = etmodel_client.get("/api/v1/transition_paths?#{query}")

        render json: response.body.to_h.merge(
          'data'  => response.body['data'],
          'links' => update_pagination_links(response.body['links'])
        )
      end

      def show
        response = etmodel_client.get("/api/v1/transition_paths/#{params.require(:id).to_i}")
        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      def create
        UpsertTransitionPath.new(
          endpoint_path: '/api/v1/transition_paths',
          method: :post
        ).call(
          params: params.permit!.to_h,
          ability: current_ability,
          client: etmodel_client
        ).either(
          ->((data, *)) { render json: data },
          ->(errors)    { service_error_response(errors) }
        )
      end

      def update
        UpsertTransitionPath.new(
          endpoint_path: "/api/v1/transition_paths/#{params.require(:id).to_i}",
          method: :put
        ).call(
          params: params.permit!.to_h,
          ability: current_ability,
          client: etmodel_client
        ).either(
          ->((data, *)) { render json: data },
          ->(error)     { service_error_response(error) }
        )
      end

      def destroy
        response = etmodel_client.delete("/api/v1/transition_paths/#{params.require(:id).to_i}")
        render json: response.body
      rescue Faraday::ResourceNotFound
        render_not_found
      end

      private

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

      def etmodel_client
        ETEngine::Auth.etmodel_client(current_user, scopes: doorkeeper_token.scopes)
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
