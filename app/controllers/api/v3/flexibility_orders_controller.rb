module Api
  module V3
    class FlexibilityOrdersController < BaseController
      before_action :find_flexibility_order

      def set
        if @flexibility_order
          @flexibility_order.update_attributes(flexibility_params)
        else
          @flexibility_order = FlexibilityOrder.create(flexibility_params)
        end

        render json: { order: @flexibility_order.order}
      end

      def get
        order = if @flexibility_order
          @flexibility_order.order
        else
          FlexibilityOrder.default_order
        end

        render json: { order: order }
      end

      private

      def find_flexibility_order
        @flexibility_order = FlexibilityOrder.find_by_scenario_id(params[:scenario_id])
      end

      def flexibility_params
        fo_params = params.require(:flexibility_order).permit(order: [])
        fo_params.merge(scenario_id: params[:scenario_id])
      end
    end
  end
end
