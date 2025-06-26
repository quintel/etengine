# frozen_string_literal: true

module Api
  module V3
    # Shows and updates flexibility and heat network orders.
    class UserSortablesController < BaseController
      include UsesScenario

      before_action :assert_valid_sortable_type, only: %i[show update]

      rescue_from NoMethodError do |e|
        raise e unless e.message.starts_with?("undefined method `permit'")

        render json: { errors: ['Invalid JSON payload'] }, status: :bad_request
      end

      # GET /api/v3/scenarios/:scenario_id/user_sortables
      # Returns all sortable orders (grouped by type, and by subtype for heat_network)
      def index
        sortables = {
          forecast_storage:        scenario.forecast_storage_order.order,
          hydrogen_supply:         scenario.hydrogen_supply_order.order,
          hydrogen_demand:         scenario.hydrogen_demand_order.order,
          space_heating:           scenario.households_space_heating_producer_order.order,
          heat_network:            {}
        }

        %i[lt mt ht].each do |subtype|
          sortables[:heat_network][subtype] = scenario.heat_network_order(subtype).order
        end

        render json: sortables
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
          Sentry.with_scope do |scope|
            scope.set_extras(
              errors: sortable.errors.full_messages,
              order: sortable_params[:order],
              scenario_id: params[:scenario_id]
            )

            Sentry.capture_message("Invalid #{params[:sortable_type].to_s.humanize.downcase} order")
          end

          render_errors(sortable)
        end
      end

      private

      def sortable
        @sortable ||= if sortable_subtype
          scenario.public_send(sortable_name, sortable_subtype)
        else
          scenario.public_send(sortable_name)
        end
      end

      def assert_valid_sortable_type
        return render_not_found if sortable_name.nil?
      end

      def sortable_name
        case params[:sortable_type].to_s
        when 'forecast_storage'  then :forecast_storage_order
        when 'heat_network'      then :heat_network_order
        when 'hydrogen_supply'   then :hydrogen_supply_order
        when 'hydrogen_demand'   then :hydrogen_demand_order
        when 'space_heating'     then :households_space_heating_producer_order
        end
      end

      # Used for the types of heat networks (lt, mt and ht)
      def sortable_subtype
        params.permit(:subtype)[:subtype] if params.key?(:subtype)
      end

      def assert_valid_sortable_subtype
        return unless sortable_subtype

        if sortable_name == :heat_network_order && %i[lt mt ht].exclude?(sortable_subtype)
          render_not_found
        end
      end

      def sortable_params
        if params.key?(:order)
          params.permit(order: [])
        else
          params.require(sortable_name).permit(order: [])
        end
      end

      def render_errors(sortable)
        render json: { errors: sortable.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
