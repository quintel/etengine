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

      before_action :merit_required

      # Downloads the load on each participant in the electricity merit order as
      # a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/merit_order.csv
      def merit_order
        render_presenter Api::V3::MeritCSVPresenter.new(
          scenario.gql.future_graph, :electricity, :merit_order,
          Api::V3::MeritCSVPresenter::NodeCustomisation.new(
            'merit_order_csv_include', 'merit_order_csv_exclude'
          )
        )
      end

      # Downloads the hourly price of electricity according to the merit order.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/electricity_price.csv
      def electricity_price
        csv_presenter = Api::V3::CarrierPriceCSVPresenter.new(
          scenario.gql.future_graph.carrier(:electricity),
          scenario.gql.future_graph.year
        )

        respond_to do |format|
          format.csv  { render_presenter csv_presenter }
          format.json { render json: csv_presenter }
        end
      end

      # Downloads the load on each participant in the heat merit order as a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/heat_network.csv
      def heat_network
        render_presenter Api::V3::MeritCSVPresenter.new(
          scenario.gql.future_graph, :steam_hot_water, :heat_network
        )
      end

      # Downloads the supply and demand of heat, including deficits and
      # surpluses due to buffering and time-shifting.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/household_heat.csv
      def household_heat_curves
        render_presenter Api::V3::HouseholdHeatCSVPresenter.new(
          scenario.gql.future_graph
        )
      end

      # Downloads the total demand and supply for hydrogen, with additional
      # columns for the storage demand and supply.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/hydrogen.csv
      def hydrogen
        render_presenter Api::V3::ReconciliationCSVPresenter.new(
          scenario.gql.future_graph, :hydrogen
        )
      end

      # Downloads the total demand and supply for network gas, with additional
      # columns for the storage demand and supply.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/network_gas.csv
      def network_gas
        render_presenter Api::V3::ReconciliationCSVPresenter.new(
          scenario.gql.future_graph, :network_gas
        )
      end

      private

      def merit_required
        unless Qernel::Plugins::Causality.enabled?(scenario.gql.future_graph)
          render :merit_required, format: :html, layout: false
        end
      end

      def render_presenter(presenter)
        send_csv(presenter.filename) do |csv|
          presenter.to_csv_rows.each { |row| csv << row }
        end
      end

      def send_csv(name)
        send_data(
          CSV.generate { |csv| yield csv },
          type: 'text/csv',
          filename: "#{ name }.#{ scenario.id }.csv"
        )
      end

      def scenario
        @scenario ||=
          Preset.get(params[:scenario_id]).try(:to_scenario) ||
          Scenario.find(params[:scenario_id])
      end
    end # CurvesController
  end # V3
end # Api
