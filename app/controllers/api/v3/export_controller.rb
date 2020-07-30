# frozen_string_literal: true

module Api
  module V3
    # Handles requests for various CSV dumps about a scenario.
    class ExportController < BaseController
      # GET /api/v3/scenarios/:id/application_demands
      #
      # Returns a CSV file containing the primary and final demands of nodes belonging to the
      # application_group group.
      def application_demands
        send_data(
          ApplicationDemandsPresenter.new(scenario).as_csv,
          type: 'text/csv',
          filename: "application_demands.#{scenario.id}.csv"
        )
      end

      # GET /api/v3/scenarios/:id/production_parameters
      #
      # Returns a CSV file containing the capacities and costs of some electricity and heat
      # producers.
      def production_parameters
        send_data(
          ProductionParametersPresenter.new(scenario).as_csv,
          type: 'text/csv',
          filename: "production_parameters.#{scenario.id}.csv"
        )
      end

      # GET /api/v3/scenarios/:id/energy_flow
      #
      # Returns a CSV file containing the energetic inputs and outputs of every node in the graph.
      def energy_flow
        send_data(
          NodeFlowPresenter.new(scenario).as_csv,
          type: 'text/csv',
          filename: "energy_flow.#{scenario.id}.csv"
        )
      end

      private

      def scenario
        @scenario ||= Scenario.find(params[:id])
      end
    end
  end
end
