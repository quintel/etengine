# Presents comprehensive emission data including gross, captured, and net emissions
# for both fossil and biogenic CO2, plus other GHG emissions.
class EmissionsExportSerializer
  # Creates a new emissions export serializer.
  #
  # Returns an EmissionsExportSerializer.
  def initialize(scenario)
    @scenario = scenario
    @graph = scenario.respond_to?(:gql) ? scenario.gql.future_graph : scenario.future_graph
  end

  # Public: Formats the emission data for the scenario as a CSV file.
  #
  # Nodes with missing or invalid emission data are excluded from the export.
  #
  # Returns a String.
  def as_csv(*)
    CSV.generate do |csv|
      csv << header_row

      nodes.each do |node|
        row = node_row(node)
        csv << row if row  # Only include valid rows (skip nil)
      end
    end
  end

  private

  def header_row
    [
      'Node',
      'CO2 production [kton CO2-eq]',
      'CO2 capture [kton CO2-eq]',
      'Other GHG emissions [kton CO2-eq]',
      'Total GHG emissions [kton CO2-eq]',
      'Biogenic CO2 emissions [kton CO2-eq]',
      'CO2 emissions end-use allocation [kton CO2-eq]'
    ]
  end

  def nodes
    # Include all energy nodes that have emissions or are final demand nodes
    @graph.nodes.select do |node|
      has_emissions?(node) || node.groups.include?(:final_demand)
    end.sort_by(&:key)
  end

  def has_emissions?(node)
    node.query.direct_co2_emission_of_fossil_gross.positive? ||
      node.query.direct_co2_emission_of_bio_gross.positive?
  rescue StandardError => e
    # Nodes without DirectEmissions module (e.g., molecule graph nodes) will raise NoMethodError
    # This is expected and we silently exclude them
    Rails.logger.debug(
      "Emissions check failed for #{node.key}: #{e.class.name} - #{e.message}"
    )
    false
  end

  def node_row(node)
    # Column 1: CO2 production (gross fossil emissions, positive)
    fossil_gross = safe_query(node, :direct_co2_emission_of_fossil_gross)

    # Column 2: CO2 capture (fossil + bio captured, negative in export)
    fossil_captured = safe_query(node, :direct_co2_emission_of_fossil_captured)
    bio_captured = safe_query(node, :direct_co2_emission_of_bio_captured)

    # Skip this node entirely if critical emission values are missing
    # This indicates calculation errors or inappropriate node types
    if fossil_gross.nil? || fossil_captured.nil? || bio_captured.nil?
      Rails.logger.warn(
        "Skipping node #{node.key} in emissions export due to missing emission values"
      )
      return nil
    end

    co2_production = to_kton(fossil_gross)
    co2_capture = to_kton(fossil_captured + bio_captured)

    # Column 3: Other GHG emissions (CH4, N2O, etc. - currently 0, future: AREA attributes)
    other_ghg = 0.0

    # Column 4: Total GHG emissions = production - capture + other
    total_ghg = co2_production - co2_capture + other_ghg

    # Column 5: Biogenic CO2 emissions (net bio emissions)
    bio_net = safe_query(node, :direct_co2_emission_of_bio)
    biogenic = bio_net.nil? ? nil : to_kton(bio_net)

    # Column 6: CO2 emissions end-use allocation (primary emissions)
    primary_fossil = safe_query(node, :primary_co2_emission_of_fossil)
    end_use_allocation = primary_fossil.nil? ? nil : to_kton(primary_fossil)

    [
      node.key,
      format_value(co2_production),
      format_value(co2_capture),
      format_value(other_ghg),
      format_value(total_ghg),
      format_value(biogenic),
      format_value(end_use_allocation)
    ]
  end

  # Safely queries a node method, returning nil on error.
  #
  # Returns nil (rather than 0.0) to distinguish between "no data" and "zero emissions".
  # Logs errors to aid debugging and monitoring.
  def safe_query(node, method)
    return nil unless node.query.respond_to?(method)

    result = node.query.public_send(method)

    # Detect invalid calculation results
    if result.nil? || result.nan? || result.infinite?
      Rails.logger.error(
        "Invalid emission value for #{node.key}.#{method}: #{result.inspect}"
      )
      return nil
    end

    result
  rescue StandardError => e
    Rails.logger.error(
      "Emission query failed for #{node.key}.#{method}: #{e.class.name} - #{e.message}"
    )
    nil
  end

  # Converts kg to kton (kiloton) - divides by 1 billion
  def to_kton(kg_value)
    kg_value / 1_000_000_000.0
  end

  # Formats value for CSV export:
  # - Empty string for nil (emissions that cannot be calculated or don't exist)
  # - 'ERROR' for invalid calculation results (e.g. NaN, Infinity)
  # - '0' for very small values below threshold (1 kg)

  def format_value(value)
    return '' if value.nil?

    if value.nan? || value.infinite?
      Rails.logger.error("Invalid value in emissions export: #{value.inspect}")
      return 'ERROR'
    end

    return '0' if value.abs < 0.000001  # 1 kg
    value.to_s
  end
end
