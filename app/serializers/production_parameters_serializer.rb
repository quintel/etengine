# Presents information about the capacity and costs of producers.
class ProductionParametersSerializer
  # Creates a new production parameters serializer.
  #
  # scenario - The Scenario whose node details are to be presented.
  #
  # Returns an ProductionParametersSerializer.
  def initialize(scenario)
    @graph = scenario.gql.future.graph
  end

  # Public: Formats the nodes for the scenario as a CSV file
  # containing the data.
  #
  # Returns a String.
  def as_csv(*)
    CSV.generate do |csv|
      csv << %w[
        key
        number_of_units
        electricity_output_capacity\ (MW)
        heat_output_capacity\ (MW)
        full_load_hours
        total_initial_investment_per_plant\ (Euros)
        fixed_operation_and_maintenance_costs_per_year\ (Euros)
        variable_operation_and_maintenance_costs_per_full_load_hour\ (Euros)
        wacc\ (factor)
        technical_lifetime\ (years)
        total_investment_over_lifetime_per_node\ (Euros)
      ]

      nodes.each do |node|
        csv << node_row(node)
      end
    end
  end

  private

  def nodes
    (
      @graph.group_nodes(:heat_production) +
      @graph.group_nodes(:electricity_production) +
      @graph.group_nodes(:cost_hydrogen_production) +
      @graph.group_nodes(:cost_hydrogen_infrastructure) +
      @graph.group_nodes(:cost_flexibility) +
      @graph.group_nodes(:cost_other)
    ).uniq.sort_by(&:key)
  end

  # Internal: Creates an array/CSV row representing the node and its
  # demands.
  def node_row(node)
    [
      node.key,
      number_of_units(node),
      node.query.electricity_output_capacity,
      node.query.heat_output_capacity,
      node.query.full_load_hours,
      node.query.total_initial_investment_per(:plant),
      node.query.fixed_operation_and_maintenance_costs_per_year,
      node.query.variable_operation_and_maintenance_costs_per_full_load_hour,
      node.query.wacc,
      node.query.technical_lifetime,
      begin
        node.query.total_investment_over_lifetime_per(:node)
      rescue StandardError
        nil
      end
    ]
  end

  # Internal: Gets the node number of units. Guards against failure for
  # nodes where it cannot be calculated.
  def number_of_units(node)
    node.query.number_of_units
  rescue
    ''
  end
end
