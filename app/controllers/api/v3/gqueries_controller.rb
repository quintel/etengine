# frozen_string_literal: true

module Api
  module V3
    # Provides the ability to retrieve information on all currently available gqueries
    class GqueriesController < ::Api::V3::BaseController
      # Returns a JSON containing a list of all available gqueries, their keys, descriptions and
      # units.
      #
      # GET /api/v3/gqueries
      def index
        render json: GqueriesSerializer.new(filtered_queries)
      end

      private

      def filtered_queries
        if labels.present?
          Gquery.filter_by(*labels.uniq)
        else
          Gquery.all
        end
      end

      def labels
        gquery_filter_params[:labels]
      end

      def gquery_filter_params
        params.permit(labels: [])
      end
    end
  end
end
