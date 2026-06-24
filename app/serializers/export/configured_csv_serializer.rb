# frozen_string_literal: true

# Serializes data from the graph based on a config file in ETSource.
#
# For example
#
#     ConfiguredCSVSerializer.new(Atlas.config(:sankey_csv), gql)
#     ConfiguredCSVSerializer.new(Atlas.config(:my_csv), gql, period: :future)
#
# The configuration should have two keys:
#
# - schema: An array of hashes describing each column in the CSV. Each hash should contain a `name`
#           key and optionally a `type` key.
# - rows:   An array of hashes, each matching the schema. Any keys contained in a hash which are not
#           present in the schema are ignored.
#
# For example:
#
#    {
#      schema: [
#        { name: 'Group' },
#        { name: 'Category' },
#        { name: 'Future year', type: 'future' }
#      ],
#      rows: [
#        { 'Group' => 'Group 1', 'Category' => 'Category 1', 'Future year' => 'some_query' },
#        { 'Group' => 'Group 1', 'Category' => 'Category 2', 'Future year' => 'another_query' }
#      ]
#    }
#
# Column types may be:
#
# - (blank):          The value from each row will be included exactly as in the config.
# - "literal":        The value from each row will be included exactly as in the config.
# - "present":        The value will be the result of evaluating the query in the present.
# - "future":         The value will be the result of evaluating the query in the future.
# - "unit":           The value will be the unit of the specified query.
# - "query":          This expands into three columns: `present`, `future` and `unit` for specified query.
# - "node_group":     Hidden column. Its value names a node group; the row is expanded into one row per
#                     node in that group. Requires a `period:` to be set on the serializer.
# - "node_attribute": The value will be the result of calling the attribute named by `value:` in the
#                     schema on node_api for each expanded node. Requires `node_group` column in schema.
#                     `value:` may be any Ruby expression evaluated on node_api via instance_eval.
#                     Supports an optional `transform:` Ruby expression evaluated with `value` bound
#                     to the result of `value:`. For example:
#                       transform: "value * 10e-6"
#                       transform: "value ? :other_ghg : :co2"
class Export::ConfiguredCSVSerializer
  # Represents the schema for a column in the CSV file.
  class Column
    attr_reader :name, :type, :label, :value, :transform

    def initialize(name, type, label: name, value: nil, transform: nil)
      @name = name
      @type = type || 'literal'
      @label = label || name
      @value = value
      @transform = transform
    end
  end

  # Creates a serializer using an ETSource config.
  #
  # period - optional :present or :future; when set, node_group rows are expanded using that graph
  #          and node_attribute columns are evaluated against it. Existing present/future/unit column
  #          types continue to work regardless of this setting.
  def initialize(config, gql, period: nil)
    @config = config.symbolize_keys
    @config[:schema] = @config[:schema].map(&:symbolize_keys)

    @columns = @config[:schema].flat_map { |c| create_columns(c) }
    @columns.delete(@node_group_column) if unpack_nodes?
    @gql = gql
    @period = period
  end

  def data
    rows = [@columns.map(&:label)]
    @config[:rows].each { |row| serialize_row(row) { |csv_row| rows << csv_row } }
    rows
  end

  def as_csv
    CSV.generate do |csv|
      data.each { |row| csv << row }
    end
  end

  private

  def serialize_row(row)
    if unpack_nodes?
      group_name = row[@node_group_column.name]
      nodes = graph_interface.group_energy_nodes(group_name) +
              graph_interface.group_molecule_nodes(group_name)
      nodes.each do |node|
        yield @columns.map { |column| serialize_node_column(column, row, node) }
      end
    else
      yield @columns.map { |column| serialize_column(column, row) }
    end
  end

  def serialize_column(column, row)
    value = row[column.name]

    return '' if value.blank?

    case column.type
    when 'future'  then @gql.future.subquery(value).to_s
    when 'present' then @gql.present.subquery(value).to_s
    when 'unit'    then Gquery.get(value).unit.to_s
    else value
    end
  end

  def serialize_node_column(column, row, node)
    case column.type
    when 'node_attribute'
      value = node.node_api.instance_eval(column.value)
      value = eval(column.transform) if column.transform
      value.to_s
    else serialize_column(column, row)
    end
  end

  def unpack_nodes?
    node_group_column.present?
  end

  def node_group_column
    @node_group_column ||= @columns.find { |c| c.type == 'node_group' }
  end

  def graph_interface
    @gql.public_send(@period)
  end

  def create_columns(column)
    if column[:type] != 'query'
      return Column.new(
        column[:name],
        column[:type],
        label: column[:label],
        value: column[:value],
        transform: column[:transform]
      )
    end

    %w[present future unit].map do |subtype|
      Column.new(
        column[:name],
        subtype,
        label: column[:"#{subtype}_label"] || default_label_for(subtype, column[:name])
      )
    end
  end

  def default_label_for(subtype, column_name)
    if subtype == 'unit'
      "#{column_name} Unit"
    else
      "#{subtype.capitalize} #{column_name}"
    end
  end
end
