# frozen_string_literal: true

module Api
  module V3
    # Shows and updates flexibility orders.
    class FlexibilityOrdersController < BaseController
      before_action :find_scenario

      rescue_from ActiveRecord::RecordNotFound do
        render json: { errors: ['Scenario not found'] }, status: 404
      end

      def show
        render json: flexibility_order || FlexibilityOrder.default
      end

      def update
        order = update_order(params[:scenario_id], order_params)

        if order.valid?
          order.save
          render json: order
        else
          # There is no reason for invalid options to have been provided, unless
          # the front-end is unaware of a change. Notify.
          Raven.capture_message(
            'Invalid flexibility order',
            extra: {
              errors: order.errors.full_messages,
              order: order_params[:order],
              scenario_id: params[:scenario_id]
            }
          )

          render_errors(order)
        end
      end

      private

      def find_scenario
        Scenario.find(params[:scenario_id])
      end

      def update_order(scenario_id, params)
        if flexibility_order
          flexibility_order.order = params[:order]
          flexibility_order
        else
          FlexibilityOrder.new(params.merge(scenario_id: scenario_id))
        end
      end

      def flexibility_order
        @flexibility_order ||=
          FlexibilityOrder.find_by(scenario_id: params[:scenario_id])
      end

      def order_params
        params.require(:flexibility_order).permit(order: [])
      end

      def render_errors(order)
        render json: { errors: order.errors.full_messages }, status: 422
      end
    end
  end
end
