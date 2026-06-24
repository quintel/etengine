# frozen_string_literal: true

module Api
  module V3
    # Handles requests for various CSV dumps about a scenario.
    class ExportController < BaseController
      before_action do
        @scenario = Scenario.find(params[:id])
        authorize!(:read, @scenario)
      end

      # GET /api/v3/scenarios/:id/energy_flow
      #
      # Returns a CSV file containing the energetic inputs and outputs of every node in the future graph.
      def energy_flow
        send_csv(
          Export::NodeFlowSerializer.new(@scenario.gql.future.graph, 'MJ'),
          'energy_flow.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/energy_flow_present
      #
      # Returns a CSV file containing the energetic inputs and outputs of every node in the present graph.
      def energy_flow_present
        send_csv(
          Export::NodeFlowSerializer.new(@scenario.gql.present.graph, 'MJ'),
          'energy_flow_present.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/molecule_flow
      #
      # Returns a CSV file containing the flow of molecules through the molecule graph.
      def molecule_flow
        send_csv(
          Export::NodeFlowSerializer.new(@scenario.gql.future.molecules, 'kg'),
          'molecule_flow.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/sankey
      #
      # Creates a CSV by reading a configuration file from ETSource consisting of literal values and
      # queries to be executed.
      def sankey
        send_csv(
          Export::ConfiguredCSVSerializer.new(Etsource::Config.sankey_csv, @scenario.gql),
          'sankey.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/storage_parameters
      #
      # Creates a CSV by reading a configuration file from ETSource consisting of literal values and
      # queries to be executed.
      def storage_parameters
        send_csv(
          Export::ConfiguredCSVSerializer.new(Etsource::Config.storage_parameters_csv, @scenario.gql),
          'storage_parameters.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/direct_emissions_present
      #
      # Returns a CSV of emissions data for all nodes in each configured node group, present graph.
      def direct_emissions_present
        send_csv(
          Export::ConfiguredCSVSerializer.new(Etsource::Config.direct_emissions_csv, @scenario.gql, period: :present),
          'direct_emissions_present.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/direct_emissions_future
      #
      # Returns a CSV of emissions data for all nodes in each configured node group, future graph.
      def direct_emissions_future
        send_csv(
          Export::ConfiguredCSVSerializer.new(Etsource::Config.direct_emissions_csv, @scenario.gql, period: :future),
          'direct_emissions_future.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/costs_parameters
      #
      # Returns a CSV file containing the cost paramaters of nodes belonging to costs groups.
      def costs_parameters
        send_csv(
          Export::CostsParametersSerializer.new(@scenario),
          'costs_parameters.%d.csv'
        )
      end

      # GET /api/v3/scenarios/:id/electricity_capacities
      #
      # Returns a CSV file containing the capacities for electricity Causality nodes.
      def electricity_capacities
        render_csv(Export::ElectricityCapacitiesCSVSerializer.new(
          @scenario.gql.future_graph, :electricity, :merit_order,
          MeritCSVSerializer::NodeCustomisation.new(
            'merit_order_csv_include', 'merit_order_csv_exclude'
          )
        ))
      end

      # GET /api/v3/scenarios/:id/hydrogen_capacities
      #
      # Returns a CSV file containing the capacities for hydrogen Causality nodes.
      def hydrogen_capacities
        render_csv(Export::ReconciliationCapacitiesCSVSerializer.new(
          @scenario.gql.future_graph, :hydrogen
        ))
      end

      # GET /api/v3/scenarios/:id/network_gas_capacities
      #
      # Returns a CSV file containing the capacities for network_gas Causality nodes.
      def network_gas_capacities
        render_csv(Export::ReconciliationCapacitiesCSVSerializer.new(
          @scenario.gql.future_graph, :network_gas
        ))
      end

      # GET /api/v3/scenarios/:id/district_heating_capacities
      #
      # Returns a CSV file containing the capacities for district_heating Causality nodes.
      def district_heating_capacities
        render_csv(Export::DistrictHeatingParticipantCapacitiesCSVSerializer.new(
          @scenario.gql.future_graph
        ))
      end

      private

      def render_csv(serializer)
        build_and_send_csv(serializer.filename) do |csv|
          serializer.to_csv_rows.each { |row| csv << row }
        end
      end

      def build_and_send_csv(filename)
        send_data(
          CSV.generate { |csv| yield csv },
          type: 'text/csv',
          filename: "#{filename}.#{@scenario.id}.csv"
        )
      end

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
