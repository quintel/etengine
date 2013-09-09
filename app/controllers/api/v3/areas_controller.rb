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

          area_data
        end

        respond_with(data)
      end

      def show
        respond_with(@area = Area.get(params[:id]))
      end
    end
  end
end
