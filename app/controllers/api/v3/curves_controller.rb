module Api
  module V3
    class CurvesController < BaseController
      respond_to :json

      respond_to :csv, only: %i[
        heat_network
        household_heat_curves
        hydrogen
        load_curves
        network_gas
        price_curve
      ]

      rescue_from ActiveRecord::RecordNotFound do
        render json: { errors: ['Scenario not found'] }, status: 404
      end

      rescue_from Atlas::DocumentNotFoundError do |e|
        raise(e) unless e.message.start_with?('Could not find a dataset')

        render(
          json: { errors: [
            'Scenario uses an unsupported area code and is no longer available: ' \
            "#{@scenario.area_code}"
          ] },
          status: 410
        )
      end

      load_and_authorize_resource :scenario

      before_action :merit_required

      # Downloads the load on each participant in the electricity merit order as
      # a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/merit_order.csv
      def merit_order
        render_serializer MeritCSVSerializer.new(
          @scenario.gql.future_graph, :electricity, :merit_order,
          MeritCSVSerializer::NodeCustomisation.new(
            'merit_order_csv_include', 'merit_order_csv_exclude'
          )
        )
      end

      # Downloads the hourly price of electricity according to the merit order.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/electricity_price.csv
      def electricity_price
        csv_serializer = CarrierPriceCSVSerializer.new(
          @scenario.gql.future_graph.carrier(:electricity),
          @scenario.gql.future_graph.year
        )

        respond_to do |format|
          format.csv  { render_serializer csv_serializer }
          format.json { render json: csv_serializer }
        end
      end

      # Downloads the load on each participant in the heat merit order as a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/heat_network.csv
      def heat_network
        render_serializer MeritCSVSerializer.new(
          @scenario.gql.future_graph, :steam_hot_water, :heat_network
        )
      end

      # Downloads the supply and demand of heat in households, including deficits and surpluses due
      # to buffering and time-shifting.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/household_heat.csv
      def household_heat_curves
        render_serializer FeverCSVSerializer.new(
          @scenario.gql.future_graph,
          %i[space_heating households_hot_water],
          'household_heat'
        )
      end

      # Downloads the supply and demand of heat in buildings, including deficits and surpluses due
      # to buffering and time-shifting.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/building_heat.csv
      def buildings_heat_curves
        render_serializer FeverCSVSerializer.new(
          @scenario.gql.future_graph,
          %i[buildings_space_heating],
          'buildings_heat'
        )
      end

      # Downloads the total demand and supply for hydrogen, with additional
      # columns for the storage demand and supply.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/hydrogen.csv
      def hydrogen
        render_serializer ReconciliationCSVSerializer.new(
          @scenario.gql.future_graph, :hydrogen
        )
      end

      # Downloads the total demand and supply for network gas, with additional
      # columns for the storage demand and supply.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/network_gas.csv
      def network_gas
        render_serializer ReconciliationCSVSerializer.new(
          @scenario.gql.future_graph, :network_gas
        )
      end

      # Downloads the residual loads of various carriers.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/residual_load.csv
      def residual_load
        render_serializer QueryCurveCSVSerializer.new(
          Etsource::Config.residual_load_csv,
          @scenario.gql,
          'residual_load'
        )
      end

      private

      def merit_required
        return if Qernel::Plugins::Causality.enabled?(@scenario.gql.future_graph)

        render(
          plain: 'Merit order and time-resolved calculation are not enabled for this scenario',
          status: :not_found
        )
      end

      def render_serializer(serializer)
        send_csv(serializer.filename) do |csv|
          serializer.to_csv_rows.each { |row| csv << row }
        end
      end

      def send_csv(name)
        send_data(
          CSV.generate { |csv| yield csv },
          type: 'text/csv',
          filename: "#{name}.#{@scenario.id}.csv"
        )
      end
    end # CurvesController
  end # V3
end # Api
