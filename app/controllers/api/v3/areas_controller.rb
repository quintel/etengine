module Api
  module V3
    class AreasController < BaseController
      respond_to :json

      def index
        data = Etsource::Dataset.region_codes.map do |code|
          area_data = Area.get(code).dup

          # For compatibility with ETModel, which expects a "useable"
          # attribute which tells it if the region may be chosen.
          area_data[:useable] = area_data[:enabled][:etmodel]
          area_data.delete(:enabled)
          area_data.delete(:init)

          area_data
        end

        render json: data
      end

      def show
        if Area.exists?(params[:id])
          render json: Area.get(params[:id])
        else
          render_not_found
        end
      end
    end
  end
end
