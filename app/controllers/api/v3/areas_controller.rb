# frozen_string_literal: true

module Api
  module V3
    class AreasController < BaseController
      respond_to :json

      def index
        # Default to sending full data for backwards compatibility.
        detailed = params.fetch(:detailed, 'true') == 'true'

        data = Etsource::Dataset.region_codes.map do |code|
          Api::V3::AreaPresenter.new(Area.get(code), detailed: detailed)
        end

        render json: data
      end

      def show
        if Area.exists?(params[:id])
          render json: Api::V3::AreaPresenter.new(
            Area.get(params[:id]),
            detailed: true
          )
        else
          render_not_found
        end
      end
    end
  end
end
