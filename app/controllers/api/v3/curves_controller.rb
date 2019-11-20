module Api
  module V3
    class CurvesController < BaseController
      respond_to :json
      respond_to :csv, only: %i[load_curves price_curve household_heat_curves]

      rescue_from ActiveRecord::RecordNotFound do
        render json: { errors: ['Scenario not found'] }, status: 404
      end

      before_action :merit_required

      # Downloads the load on each participant in the merit order as a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/merit/loads.csv
      def load_curves
        send_csv('loads') do |csv|
          merit_order.load_curves.each { |row| csv << row }
        end
      end

      # Downloads the merit order price for each hour of the year as a CSV.
      #
      # GET /api/v3/scenarios/:scenario_id/merit/price.csv
      def price_curve
        send_csv('price') do |csv|
          merit_order.price_curve.each { |row| csv << [row] }
        end
      end

      # Downloads the supply and demand of heat, including deficits and
      # surpluses due to buffering and time-shifting.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/household_heat.csv
      def household_heat_curves
        presenter =
          Api::V3::HouseholdHeatCSVPresenter.new(scenario.gql.future_graph)

        send_csv('household_heat') do |csv|
          presenter.to_csv_rows.each { |row| csv << row }
        end
      end

      # Downloads the total demand and supply for hydrogen, with additional
      # columns for the storage demand and supply.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/hydrogen.csv
      def hydrogen
        presenter = Api::V3::ReconciliationCSVPresenter.new(
          scenario.gql.future_graph, :hydrogen
        )

        send_csv('hydrogen') do |csv|
          presenter.to_csv_rows.each { |row| csv << row }
        end
      end

      # Downloads the total demand and supply for network gas, with additional
      # columns for the storage demand and supply.
      #
      # GET /api/v3/scenarios/:scenario_id/curves/network_gas.csv
      def network_gas
        presenter = Api::V3::ReconciliationCSVPresenter.new(
          scenario.gql.future_graph, :network_gas
        )

        send_csv('network_gas') do |csv|
          presenter.to_csv_rows.each { |row| csv << row }
        end
      end

      private

      def merit_required
        unless Qernel::Causality.enabled?(scenario.gql.future_graph)
          render :merit_required, format: :html, layout: false
        end
      end

      def send_csv(name)
        send_data(
          CSV.generate { |csv| yield csv },
          type: 'text/csv',
          filename: "#{ name }.#{ scenario.id }.csv"
        )
      end

      def merit_order
        scenario.gql.future_graph.plugin(:merit).order
      end

      def scenario
        @scenario ||=
          Preset.get(params[:scenario_id]).try(:to_scenario) ||
          Scenario.find(params[:scenario_id])
      end
    end # CurvesController
  end # V3
end # Api
