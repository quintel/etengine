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
        render json: GqueriesSerializer.new(Gquery.all)
      end
    end
  end
end
