# frozen_string_literal: true

module Api
  module V3
    # Shows and updates heat network orders.
    class HeatNetworkOrdersController < BaseController
      rescue_from ActiveRecord::RecordNotFound do
        render json: { errors: ['Scenario not found'] }, status: 404
      end

      rescue_from NoMethodError do |e|
        raise e unless e.message.starts_with?("undefined method `permit'")

        render json: { errors: ['Invalid JSON payload'] }, status: 400
      end

      def show
        render json: heat_network_order
      end

      def update
        heat_network_order[:order] = heat_network_order_params[:order]

        if heat_network_order.valid?
          heat_network_order.save
          render json: heat_network_order
        else
          # There is no reason for invalid options to have been provided, unless
          # the front-end is unaware of a change. Notify.
          Raven.capture_message(
            'Invalid heat network order',
            extra: {
              errors: heat_network_order.errors.full_messages,
              order: heat_network_order_params[:order],
              scenario_id: params[:scenario_id]
            }
          )

          render_errors(heat_network_order)
        end
      end

      private

      def scenario
        @scenario ||= Scenario.find(params[:scenario_id])
      end

      def heat_network_order
        @heat_network_order ||= scenario.heat_network_order
      end

      def heat_network_order_params
        params.require(:heat_network_order).permit(order: [])
      end

      def render_errors(heat_network_order)
        render json: { errors: heat_network_order.errors.full_messages }, status: 422
      end
    end
  end
end
