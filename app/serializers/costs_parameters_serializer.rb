# frozen_string_literal: true

# Presents the CAPEX, OPEX and other cost parameters of nodes that are part of
# costs groups as a CSV file.
class CostsParametersSerializer
  QUERIES = {
    costs_building_and_installations_households: %w[
      costs_of_insulation_apartments
      costs_of_insulation_corner_houses
      costs_of_insulation_detached_houses
      costs_of_insulation_semi_detached_houses
      costs_of_insulation_terraced_houses
      households_ht_heat_delivery_system
      households_mt_heat_delivery_system
      households_lt_heat_delivery_system
    ],
    costs_building_and_installations_buildings: %w[
      costs_of_insulation_buildings
      buildings_ht_heat_delivery_system
      buildings_mt_heat_delivery_system
      buildings_lt_heat_delivery_system
    ],
    costs_storage_and_conversion_storage: %w[
      costs_hydrogen_storage
      heat_infrastructure_ht_storage
      heat_infrastructure_mt_storage
      heat_infrastructure_lt_storage
    ],
    costs_carriers_biomass: %w[
      costs_carriers_biomass
    ],
    costs_carriers_oil_and_products: %w[
      costs_carriers_oil_and_products
    ],
    costs_carriers_coal_and_products: %w[
      costs_carriers_coal_and_products
    ],
    costs_carriers_uranium: %w[
      costs_carriers_uranium
    ],
    costs_carriers_heat: %w[
      costs_carriers_heat
    ],
    costs_carriers_natural_gas: %w[
      costs_carriers_natural_gas
    ],
    costs_carriers_waste: %w[
      costs_carriers_waste
    ],
    costs_carriers_electricity: %w[
      costs_carriers_electricity
    ],
    costs_carriers_hydrogen: %w[
      costs_carriers_hydrogen
    ],
    costs_carriers_liquid_hydrogen: %w[
      costs_carriers_liquid_hydrogen
    ],
    costs_carriers_lohc: %w[
      costs_carriers_lohc
    ],
    costs_carriers_ammonia: %w[
      costs_carriers_ammonia
    ],
    costs_infrastructure_electricity: %w[
      lv_net_costs_present
      lv_net_costs_delta_present_future
      lv_mv_trafo_costs_present
      lv_mv_trafo_costs_delta_present_future
      mv_net_costs_present
      mv_net_costs_delta_present_future
      mv_hv_trafo_costs_present
      mv_hv_trafo_costs_delta_present_future
      hv_net_costs_present
      hv_net_costs_delta_present_future
      interconnection_net_costs_present
      interconnection_net_costs_delta_present_future
      offshore_net_costs_present
      offshore_net_costs_delta_present_future
    ],
    costs_infrastructure_heat: %w[
      heat_infrastructure_ht_primary_pipelines
      heat_infrastructure_ht_distribution_pipelines
      heat_infrastructure_ht_distribution_stations
      heat_infrastructure_ht_indoor
      heat_infrastructure_mt_primary_pipelines
      heat_infrastructure_mt_distribution_pipelines
      heat_infrastructure_mt_distribution_stations
      heat_infrastructure_mt_indoor
      heat_infrastructure_lt_primary_pipelines
      heat_infrastructure_lt_distribution_pipelines
      heat_infrastructure_lt_distribution_stations
      heat_infrastructure_lt_indoor
    ],
    costs_infrastructure_network_gas: %w[
      gas_network_costs
    ]
  }.freeze

  CSV_HEADER = [
    'Group', 'Subgroup', 'Key',
    'Total costs (eur)', 'Total CAPEX (eur)', 'Total OPEX (eur)',
    'Capital costs (eur)', 'Depreciation costs (eur)',
    'Fixed operational and maintenance costs (eur)', 'Variable operational and maintenance costs (eur)',
    'Total investment over lifetime (eur)', 'WACC', 'Construction time (years)', 'Technical lifetime (years)',
    'CO2 emission costs (eur)', 'Number of units'
    # , 'Fuel costs (eur)'
  ]

  # Creates a new costs csv serializer.
  #
  # scenario - The Scenario whose node costs are to be presented.
  #
  # Returns a CostsCsvSerializer.
  def initialize(scenario)
    @graph = scenario.gql.future.graph
    @molecule_graph = Qernel::Plugins::Molecules.new(@graph).molecule_graph
    @gql = scenario.gql
  end

  # Public: Formats the nodes and queries for the scenario as a CSV file
  # containing the data.
  #
  # Returns a String.
  def as_csv(*)
    perform_queries!

    CSV.generate do |csv|
      csv << CSV_HEADER

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
    # Process nodes for the energy graph first
    node_rows_for_subgroup(@graph, group, subgroup) +
      # then process nodes for the molecule graph
      node_rows_for_subgroup(@molecule_graph, group, subgroup) +
      # and finally process queries for the energy graph
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
  def node_rows_for_subgroup(graph, group, subgroup)
    graph.group_nodes(:"#{group}_#{subgroup}").map do |node|
      [
        group, # Group
        subgroup, # Subgroup
        node.key, # Key
        format_num(node.query.total_costs_per(:node) - 
          node.query.fuel_costs_per(:node)), # Total costs (eur)
        format_num(node.query.capital_expenditures_excluding_ccs_per(:node) + 
          node.query.capital_expenditures_ccs_per(:node)), # Total CAPEX (eur)
        format_num(node.query.operating_expenses_excluding_ccs_per(:node) + 
          node.query.operating_expenses_ccs_per(:node)), # Total OPEX (eur)
        format_num(node.query.cost_of_capital_per(:node)), # 'Capital costs (eur)'
        format_num(node.query.depreciation_costs_per(:node)), # 'Depreciation costs (eur)'
        format_num(node.query.fixed_operation_and_maintenance_costs_per_year *
          node.query.number_of_units), # 'Fixed operational and maintenance costs (eur)'
        format_num(node.query.variable_operation_and_maintenance_costs_per(:node)), # 'Variable operational and maintenance costs (eur)'
        format_num(node.query.total_investment_over_lifetime_per(:node)), # 'Total investment over lifetime (eur)'
        format_num(node.query.wacc), # 'WACC'
        format_num(node.query.construction_time), # 'Construction time (years)'
        format_num(node.query.technical_lifetime), # 'Technical lifetime (years)'
        format_num(node.query.co2_emissions_costs_per(:node)), # CO2 emission costs (eur)
        format_num(node.query.number_of_units), # Number of units
        # format_num(node.query.fuel_costs_per(:node)) # Fuel costs (eur) --> to be removed
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
  # Returns an array containing the summed values of the requested group and optional subgroup.
  def group_total_row(group, subgroup = nil)
    rows = \
      if subgroup.present?
        rows_for_subgroup(group, subgroup)
      else
        rows_for(group, false)
      end

    # Prefill the row with zeros
    totals_row = Array.new(CSV_HEADER.length) { 0.0 }

    # Add column identifier names to the first three columns
    totals_row[0] = group
    totals_row[1] = subgroup || 'Group total'
    totals_row[2] = subgroup.present? ? 'Subgroup total' : ''

    # Return the totals row with empty values (zeros) if no rows are present
    return totals_row if rows.empty?

    # Sum all columns one by one, except for the first three identifier columns
    (3..(CSV_HEADER.length - 1)).each { |idx| totals_row[idx] = rows.sum { |row| row[idx].to_f } }

    totals_row
  end

  # Internal: Returns a row based on a query.
  #
  # If a query doesnt exist and/or has no result, nil is returned
  def query_row(group, subgroup, query, name = '')
    [
      group,
      subgroup,
      name.presence || query,
      format_num(@query_results["#{query}_annualised_costs"]), # Total costs (eur)
      format_num(@query_results["#{query}_capex"]),
      format_num(@query_results["#{query}_opex"]),
      format_num(@query_results["#{query}_capital_costs"]),
      format_num(@query_results["#{query}_depreciation_costs"]),
      format_num(@query_results["#{query}_fixed_operation_and_maintenance_costs"]),
      format_num(@query_results["#{query}_variable_operation_and_maintenance_costs"]),
      format_num(@query_results["#{query}_investment_costs"]),
      format_num(@query_results["#{query}_wacc"]),
      format_num(@query_results["#{query}_construction_time"]),
      format_num(@query_results["#{query}_technical_lifetime"]),
      nil, # CO2 emission costs (eur)
      nil, # Number of units
      # nil  # Fuel costs (eur) --> to be removed
    ]
  end

  # Queries --------------------------------------------------------------------

  # Internal: Performs the neccesary queries
  #
  # For each base key it performs a set of queries: [{key}, {key}_capex, ...]
  # Skips queries that could not be found. Saves the results in @query_results.
  def perform_queries!
    as_queries = queries.flat_map do |key| 
      [
        Gquery.get(key),
        Gquery.get("#{key}_annualised_costs"),
        Gquery.get("#{key}_capex"),
        Gquery.get("#{key}_opex"),
        Gquery.get("#{key}_capital_costs"),
        Gquery.get("#{key}_depreciation_costs"),
        Gquery.get("#{key}_fixed_operation_and_maintenance_costs"),
        Gquery.get("#{key}_variable_operation_and_maintenance_costs"),
        Gquery.get("#{key}_investment_costs"),
        Gquery.get("#{key}_wacc"),
        Gquery.get("#{key}_technical_lifetime")
      ]
    end.compact
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
    %w[households buildings industry agriculture]
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
       electricity hydrogen liquid_hydrogen lohc ammonia]
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
    %w[ccus]
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
