# frozen_string_literal: true

module Api
  module V3
    # Shows and updates flexibility and heat network orders.
    class UserSortablesController < BaseController
      before_action :assert_valid_sortable_type

      rescue_from ActiveRecord::RecordNotFound do
        render json: { errors: ['Scenario not found'] }, status: 404
      end

      def show
        render json: sortable
      end

      def update
        sortable[:order] = sortable_params[:order]

        if sortable.valid?
          sortable.save
          render json: sortable
        else
          # There is no reason for invalid options to have been provided, unless
          # the front-end is unaware of a change. Notify.
          Raven.capture_message(
            "Invalid #{sortable_name.to_s.humanize.downcase}",
            extra: {
              errors: sortable.errors.full_messages,
              order: sortable_params[:order],
              scenario_id: params[:scenario_id]
            }
          )

          render_errors(sortable)
        end
      end

      private

      def scenario
        @scenario ||= Scenario.find(params[:scenario_id])
      end

      def sortable
        @sortable ||= scenario.public_send(sortable_name)
      end

      def assert_valid_sortable_type
        return render_not_found if sortable_name.nil?
      end

      def sortable_name
        case params[:sortable_type]
        when :flexibility then :flexibility_order
        when :heat_network then :heat_network_order
        end
      end

      def sortable_params
        params.require(sortable_name).permit(order: [])
      end

      def render_errors(sortable)
        render json: { errors: sortable.errors.full_messages }, status: 422
      end
    end
  end
end
