# frozen_string_literal: true

# Serializes data from the graph based on a config file in ETSource.
#
# For example
#
#     ConfiguredCSVSerializer.new(Atlas.config(:sankey_csv))
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
# - (blank):   The from each row will be included exactly as in the config.
# - "literal": The from each row will be included exactly as in the config.
# - "present": The value will be the result of evaluating the query in the present.
# - "future":  The value will be the result of evaluating the query in the future.
# - "unit":    The value will be the unit of the specified query.
# - "query":   This expands into three columns: `present`, `future` and `unit` for specified query.
class ConfiguredCSVSerializer
  # Represents the schema for a column in the CSV file.
  class Column
    attr_reader :name, :type, :label

    def initialize(name, type, label: name)
      @name = name
      @type = type || 'literal'
      @label = label || name
    end
  end

  # Creates a serializer using an ETSource config.
  def initialize(config, gql)
    @config = config.symbolize_keys
    @config[:schema] = @config[:schema].map(&:symbolize_keys)

    @columns = @config[:schema].flat_map { |c| create_columns(c) }

    @gql = gql
  end

  def data
    [@columns.map(&:label)] + @config[:rows].map { |row| serialize_row(row) }
  end

  def as_csv
    CSV.generate do |csv|
      data.each { |row| csv << row }
    end
  end

  private

  def serialize_row(row)
    @columns.map do |column|
      value = row[column.name]

      next '' if value.blank?

      case column.type
      when 'future'  then @gql.future.subquery(value).to_s
      when 'present' then @gql.present.subquery(value).to_s
      when 'unit'    then Gquery.get(value).unit.to_s
      else value
      end
    end
  end

  def create_columns(column)
    return Column.new(column[:name], column[:type]) if column[:type] != 'query'

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
