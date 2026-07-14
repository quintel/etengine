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
# - rows:   Either an array of hashes, each matching the schema (query-driven mode; any keys not
#           present in the schema are ignored), or a hash `{ require: <mapping column>, order_by:
#           <mapping column> }` (mapping-driven mode, see below). `order_by` is optional.
#
# Query-driven example:
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
#
# Mapping-driven mode: `rows: { require: <mapping column> }` selects every (sector label, use) pair
# in the sector mapping (see Atlas::SectorMapping) whose cell in `require`'s column has a value, in
# mapping-file order by default. An optional `order_by: <mapping column>` instead orders pairs by the
# raw display value of that column (ascending string comparison), regardless of whether the column is
# included in `schema:`; a pair whose `order_by` cell is blank/`-` sorts last, and pairs tied on
# `order_by` keep their relative mapping-file order. Each pair expands to the energy and molecule
# nodes whose own `sector_label` and `use` match the pair AND which belong to the node's `:emissions`
# group (key-sorted). A pair with zero labelled nodes, or whose only matching nodes aren't in the
# `:emissions` group, legally yields zero rows. Requires a `period:` to be set on the serializer. Two
# extra column types apply:
#
# - "node_attribute": The value will be the result of calling the attribute named by `value:` in the
#                     schema on node_api for each expanded node. `value:` may be any Ruby expression
#                     evaluated on node_api via instance_eval. A nil result (e.g. a node not in the
#                     :emissions group) renders as an empty string without evaluating `transform`.
#                     Otherwise, an optional `transform:` Ruby expression is evaluated with `value`
#                     bound to the result of `value:`. For example:
#                       transform: "value * 10e-6"
#                       transform: "value ? :other_ghg : :co2"
# - "sector_mapping": The value will be the raw display value (never a normalized slug) of the
#                     mapping column named by `value:`, for the row's pair. A `-`/blank mapping cell
#                     renders as an empty string.
#
# An unknown mapping column named by `require:`, `order_by:`, or a `sector_mapping` column's `value:`
# raises Export::ConfiguredCSVSerializer::UnknownMappingColumnError at construction, naming the valid
# columns.
module Export
  class ConfiguredCSVSerializer # rubocop:disable Style/Documentation
    class UnknownMappingColumnError < StandardError
    end

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
    # period - optional :present or :future; required when `rows:` is mapping-driven.
    def initialize(config, gql, period: nil)
      @config = config.symbolize_keys
      @config[:schema] = @config[:schema].map(&:symbolize_keys)
      @config[:rows] = @config[:rows].symbolize_keys if @config[:rows].is_a?(Hash)

      @columns = @config[:schema].flat_map { |c| create_columns(c) }
      @gql = gql
      @period = period

      validate_mapping_references! if mapping_driven?
    end

    def data
      rows = [@columns.map(&:label)]

      if mapping_driven?
        serialize_mapping_rows { |row| rows << row }
      else
        @config[:rows].each { |row| rows << @columns.map { |column| serialize_column(column, row) } }
      end

      rows
    end

    def as_csv
      CSV.generate do |csv|
        data.each { |row| csv << row }
      end
    end

    private

    def mapping_driven?
      @config[:rows].is_a?(Hash)
    end

    def membership_scheme
      @config[:rows][:require].to_sym
    end

    def order_scheme
      @config[:rows][:order_by]&.to_sym
    end

    def serialize_mapping_rows
      eligible_rows.each do |raw_row|
        nodes_for_pair(raw_row.pair).each do |node|
          yield @columns.map { |column| serialize_mapping_column(column, raw_row, node) }
        end
      end
    end

    # Rows whose `require:` cell has a value, in mapping-file order. When `order_by:` is set, sorted
    # by that column's raw value instead (blank/`-` last), with ties broken by mapping-file order.
    def eligible_rows
      rows = sectors.raw_rows.select { |raw_row| raw_row.cells[membership_scheme] }
      return rows unless order_scheme

      rows.each_with_index.sort_by { |raw_row, index| [raw_row.cells[order_scheme].nil? ? 1 : 0, raw_row.cells[order_scheme].to_s, index] }
        .map(&:first)
    end

    def serialize_mapping_column(column, raw_row, node)
      case column.type
      when 'node_attribute'
        value = node.node_api.instance_eval(column.value)
        return '' if value.nil?

        value = eval(column.transform) if column.transform
        value.to_s
      when 'sector_mapping'
        raw_row.cells[column.value.to_sym].to_s
      else
        ''
      end
    end

    def nodes_for_pair(pair)
      nodes = %i[energy molecules].flat_map do |graph_type|
        sectors.node_index(graph_type).fetch(pair, []).filter_map do |key|
          node_for(graph_type, key)
        end
      end
      nodes.select(&:emissions?).sort_by { |node| node.node_api.key.to_s }
    end

    def node_for(graph_type, key)
      graph_type == :molecules ? graph_interface.molecules.node(key) : graph_interface.graph.node(key)
    end

    def graph_interface
      @gql.public_send(@period)
    end

    def sectors
      @sectors ||= Etsource::Sectors.new
    end

    def validate_mapping_references!
      valid = sectors.mapping.keys
      references = [@config[:rows][:require], @config[:rows][:order_by]] + @columns.select { |c|
        c.type == 'sector_mapping'
      }.map(&:value)

      references.compact.each do |reference|
        next if valid.include?(reference.to_sym)

        raise UnknownMappingColumnError,
          "Unknown sector mapping column #{reference.inspect}. " \
          "Valid columns: #{valid.map(&:inspect).join(', ')}."
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
end
