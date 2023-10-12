# frozen_string_literal: true

# Presents the CAPEX, OPEX and other cost parameters of nodes that are part of
# costs groups as a CSV file.
class CostsParametersSerializer
  QUERIES = {
    costs_building_and_installations_households: %w[
      costs_building_and_installations_households_insulation
      costs_building_and_installations_households_heat_delivery_system
    ],
    costs_building_and_installations_buildings: %w[
      costs_building_and_installations_buildings_insulation
      costs_building_and_installations_buildings_heat_delivery_system
    ],
    costs_storage_and_conversion_storage: %w[
      costs_hydrogen_storage
      heat_infrastructure_storage_annualised_costs
    ],
    costs_infrastructure_electricity: %w[
      total_costs_of_electricity_network_calculation
    ],
    costs_infrastructure_heat: %w[
      costs_infrastructure_heat
    ],
    costs_infrastructure_hydrogen: %w[
      
    ],
    costs_infrastructure_network_gas: %w[
      gas_network_total_costs
    ],
    costs_co2_molecule_nodes: %w[
      costs_co2_energy_graph
    ],
    costs_co2_energy_nodes: %w[
      costs_molecule_graph
    ]
  }.freeze

  # Creates a new costs csv serializer.
  #
  # scenario - The Scenario whose node costs are to be presented.
  #
  # Returns a CostsCsvSerializer.
  def initialize(scenario)
    @graph = scenario.gql.future.graph
    @gql = scenario.gql
  end

  # Public: Formats the nodes and queries for the scenario as a CSV file
  # containing the data.
  #
  # Returns a String.
  def as_csv(*)
    perform_queries!

    CSV.generate do |csv|
      csv << [
        'Group', 'Subgroup', 'Key',
        'CAPEX ex ccs (Euro)', 'OPEX ex ccs (Euro)', 'CAPEX ccs (Euro)', 'OPEX ccs (Euro)',
        'Total ex ccs (Euro)', 'Number of units', 'Total input (MJ)', 'Total output (MJ)'
      ]

      groups_with_subtotal.each do |group|
        rows_for(group).each { |row| csv << row }
        csv << group_total_row(group)
      end

      groups_without_subtotal.each do |group|
        rows_for(group, false).each { |row| csv << row }
        csv << group_total_row(group)
      end
    end
  end

  private

  # Row generation -------------------------------------------------------------

  # Round all number to 2
  def format_num(value)
    value&.round(2)
  end

  # Internal: Creates rows for each subgroup in the group
  #
  # group         - Symbol, the name of the main group. Should have a corresponding method
  #                 containing its subgroups.
  # add_subtotal  - optional, if true adds a subtotal row to each subgroup.
  #
  # Returns an array of arrays of Strings: an array containing all rows for the group
  def rows_for(group, add_subtotal = true)
    send(group).flat_map do |subgroup|
      if add_subtotal
        rows_for_subgroup(group, subgroup) << group_total_row(group, subgroup)
      else
        rows_for_subgroup(group, subgroup)
      end
    end
  end

  # Internal: Returns rows for the subgroup, combining group node rows and query
  # rows
  #
  # Returns an array of arrays of Strings: an array containing all rows for the subgroup
  def rows_for_subgroup(group, subgroup)
    node_rows_for_subgroup(group, subgroup) +
      query_rows_for_subgroup(group, subgroup)
  end

  # Internal: Returns rows based on the nodes that are part of the subgroup
  #
  # Retrieves all nodes belonging to the given group_subgroup combination and
  # creates a row for each of them. A row contains all four CAPEX and OPEX, ccs
  # and excluding_css combinations
  #
  # Returns an array of arrays of Strings: an array containing all node rows for the subgroup
  # Returns an empty [] when no nodes were in the group.
  def node_rows_for_subgroup(group, subgroup)
    @graph.group_nodes(:"#{group}_#{subgroup}").map do |node|
      [
        group,
        subgroup,
        node.key,
        format_num(node.query.capital_expenditures_excluding_ccs_per(:node)),
        format_num(node.query.operating_expenses_excluding_ccs_per(:node)),
        format_num(node.query.capital_expenditures_ccs_per(:node)),
        format_num(node.query.operating_expenses_ccs_per(:node)),
        nil,
        format_num(node.query.number_of_units),
        format_num(node_flow(node, :inputs)),
        format_num(node_flow(node, :outputs))
      ]
    end
  end

  # Internal: Returns rows based on the queries that are part of the subgroup
  #
  # Retrives al 'extra' queries that should be shown with this group_subgroup. Creates a
  # query row for each of them.
  #
  # Returns an array of arrays of Strings: an array containing all query rows for the subgroup
  # Returns an empty [] when no queries were requested.
  def query_rows_for_subgroup(group, subgroup)
    queries_for(group, subgroup).map { |query| query_row(group, subgroup, query) }
  end

  # Internal: The row containing the (sub)total of the (sub)group
  #
  # If no subgroup was supplied, gets the query with the name of the main group
  def group_total_row(group, subgroup = nil)
    query = subgroup ? "#{group}_#{subgroup}" : group.to_s
    subgroup_name = subgroup ? subgroup : 'Group total'
    query_row(group, subgroup_name, query, 'Total')
  end

  # Internal: Returns a row based on a query.
  #
  # Has no CAPEX or OPEX, so its value is displayed in the Total column.
  def query_row(group, subgroup, query, name = '')
    [
      group,
      subgroup,
      name.presence || query,
      nil, nil, nil, nil,
      format_num(@query_results[query]),
      nil, nil, nil
    ]
  end

  # Queries --------------------------------------------------------------------

  # Internal: Performs the neccesary queries
  #
  # Skips queries that could not be found. Saves the results in @query_results.
  def perform_queries!
    as_queries = queries.map { |key| Gquery.get(key) }.compact
    @query_results = as_queries.to_h do |query|
      [query.key, @gql.query_future(query)]
    end
  end

  # Internal: Returns the queries that should be mentioned in the group_subgroup
  def queries_for(group, subgroup)
    QUERIES[:"#{group}_#{subgroup}"] || []
  end

  # Internal: Returns all queries that are used to query subtotals of (sub)groups
  def subtotal_queries
    groups_with_subtotal.flat_map { |g| send(g).map { |s| :"#{g}_#{s}" } }
  end

  # Internal: Returns all queries that should be performed: totals, subtotals and
  # extra queries
  def queries
    QUERIES.values.flatten + subtotal_queries + groups!
  end

  # Groups ---------------------------------------------------------------------

  # Internal: Returns all groups for which a subtotal line per subgroup should be added
  def groups_with_subtotal
    %i[
      costs_building_and_installations
      costs_production costs_storage_and_conversion
      costs_carriers
    ]
  end

  # Internal: Returns all groups that should not have a subtotal line per subgroup
  def groups_without_subtotal
    %i[costs_infrastructure costs_co2]
  end

  # Internal: Returns all groups
  def groups!
    groups_with_subtotal + groups_without_subtotal
  end

  # Internal: Sectors for which the cost_building_and_installations group is valid
  #
  # Has subtotal queries
  def costs_building_and_installations
    %w[households buildings industry transport agriculture]
  end

  # Internal: Production for which the costs_production group is valid
  #
  # Has subtotal queries
  def costs_production
    %w[power_plants chp_plants heat_plants dedicated_hydrogen_production biomass other]
  end

  # Internal: Categories within costs_storage_and_conversion
  #
  # Has subtotal queries
  def costs_storage_and_conversion
    %w[p2p p2g p2h storage]
  end

  # Internal: Carriers for which the costs_carriers group is valid
  #
  # This group only needs subtotal group queries
  def costs_carriers
    %w[biomass oil_and_products coal_and_products uranium heat natural_gas waste
       electricity hydrogen ammonia]
  end

  # Internal: Carriers for which the costs_infrastructure group is valid
  #
  # This group does not need subtotal group queries
  def costs_infrastructure
    %w[electricity heat hydrogen network_gas]
  end

  # Internal: Subgroups of the costs_co2 group
  #
  # This group does not need subtotal group queries
  def costs_co2
    %w[molecule_nodes energy_nodes]
  end

  # Internal: Sums the input or output flows of the node
  #
  # Copied from inspect_helper
  def node_flow(node, direction)
    slots = node.public_send(direction == :inputs ? :inputs : :outputs)

    return nil if slots.none?

    slots.sum do |slot|
      if slot.edges.any?
        slot.external_value
      else
        # Fallback for left-most or right-most slots with no edges.
        slot.node.demand * slot.conversion
      end
    end
  end
end
