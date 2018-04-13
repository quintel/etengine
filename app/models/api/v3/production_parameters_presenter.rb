module Api
  module V3
    # Presents information about the capacity and costs of producers.
    class ProductionParametersPresenter
      # Creates a new production parameters presenter.
      #
      # scenario - The Scenario whose converter details are to be presented.
      #
      # Returns an ProductionParametersPresenter.
      def initialize(scenario)
        @graph = scenario.gql.future.graph
      end

      # Public: Formats the converters for the scenario as a CSV file
      # containing the data.
      #
      # Returns a String.
      def as_csv(*)
        CSV.generate do |csv|
          csv << %w[
            key
            number_of_units
            electricity_output_capacity
            heat_output_capacity
            full_load_hours
            initial_investment_per_plant
            fixed_operation_and_maintenance_costs_per_year
            variable_operation_and_maintenance_costs_per_full_load_hour
            wacc
            technical_lifetime
            total_investment_over_lifetime_per_converter
          ]

          converters.each do |converter|
            csv << converter_row(converter)
          end
        end
      end

      private

      def converters
        ( @graph.group_converters(:heat_production) +
          @graph.group_converters(:electricity_production) +
          @graph.group_converters(:cost_hydrogen_production) + 
          @graph.group_converters(:cost_hydrogen_infrastructure) + 
          @graph.group_converters(:cost_other)
        ).uniq.sort_by(&:key)
      end

      # Internal: Creates an array/CSV row representing the converter and its
      # demands.
      def converter_row(converter)
        [
          converter.key,
          number_of_units(converter),
          converter.query.electricity_output_capacity,
          converter.query.heat_output_capacity,
          converter.query.full_load_hours,
          converter.query.initial_investment_per(:plant),
          converter.query.fixed_operation_and_maintenance_costs_per_year,
          converter.query.variable_operation_and_maintenance_costs_per_full_load_hour,
          converter.query.wacc,
          converter.query.technical_lifetime,
          begin
            converter.query.total_investment_over_lifetime_per(:converter)
          rescue StandardError
            nil
          end
        ]
      end

      # Internal: Gets the converter number of units. Guards against failure for
      # converters where it cannot be calculated.
      def number_of_units(converter)
        converter.query.number_of_units
      rescue
        ''
      end
    end
  end
end
