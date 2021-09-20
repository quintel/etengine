# frozen_string_literal: true

module Api
  module V3
    # Handles requests for various CSV dumps about a scenario.
    class ExportController < BaseController
      before_action do
        @scenario = Scenario.find(params[:id])
        authorize!(:read, @scenario)
      end

      # GET /api/v3/scenarios/:id/application_demands
      #
      # Returns a CSV file containing the primary and final demands of nodes belonging to the
      # application_group group.
      def application_demands
        send_csv(ApplicationDemandsSerializer.new(@scenario), 'application_demands.%d.csv')
      end

      # GET /api/v3/scenarios/:id/production_parameters
      #
      # Returns a CSV file containing the capacities and costs of some electricity and heat
      # producers.
      def production_parameters
        send_csv(ProductionParametersSerializer.new(@scenario), 'production_parameters.%d.csv')
      end

      # GET /api/v3/scenarios/:id/energy_flow
      #
      # Returns a CSV file containing the energetic inputs and outputs of every node in the graph.
      def energy_flow
        send_csv(NodeFlowSerializer.new(@scenario.gql.future.graph, 'MJ'), 'energy_flow.%d.csv')
      end

      # GET /api/v3/scenarios/:id/molecule_flow
      #
      # Returns a CSV file containing the flow of molecules through the molecule graph.
      def molecule_flow
        send_csv(
          NodeFlowSerializer.new(@scenario.gql.future.molecules, 'kg'),
          'molecule_flow.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/costs_parameters
      #
      # Returns a CSV file containing the cost paramaters of nodes belonging to costs groups.
      def costs_parameters
        send_csv(CostsParametersSerializer.new(scenario), 'costs_parameters.%d.csv')
      end

      private

      def send_csv(serializer, filename_template)
        send_data(
          serializer.as_csv,
          type: 'text/csv',
          filename: format(filename_template, @scenario.id)
        )
      end
    end
  end
end
