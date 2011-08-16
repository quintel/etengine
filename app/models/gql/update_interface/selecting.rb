module Gql::UpdateInterface::Selecting

  ##
  # Returns an array of converters of a graph that match the given select_query.
  # It matches converters by sector_keys, full_keys, Converter#converter_id (Numeric)
  #
  # =Examples
  #
  # == converter key:
  # select("energy_demand_households") => [<Converter key:energy_demand_households>]
  #
  # == sector key:
  # select("sector_households") => [<Converter key:energy_demand_households>, ...]
  #
  # == chain keys with _AND_:
  # select("sector_households_AND_sector_industry")
  #
  # == Intersection and Difference with two groups
  # select("group_final_demand_cbs_INTERSECTION_sector_households")
  # select("group_final_demand_cbs_DIFFERENCE_sector_households")
  #
  # e.g.
  # select("1_AND_2_AND_3_INTERSECTION_1_AND_2")
  # => [converter_1, converter_2]
  # select("1_AND_2_AND_3_DIFFERENCE_1_AND_2")
  # => [converter_3]
  #
  # @param select_query [String] Select part of query. Contains keys for converters, sectors
  # @param graph [Qernel::Graph] The Graph in which we're looking for converters
  # @return [Array<Qernel::Converter>] Array of Qernel::Converter
  # @raise [GqlError] if no converters have been found
  #
  def select(select_query, graph = nil)
    group1_query, operator, group2_query = select_query.split(/_(INTERSECTION|DIFFERENCE)_/)

    converters = select_converters(group1_query, graph)

    case operator
      when 'INTERSECTION'
        converters & select_converters(group2_query, graph)
      when 'DIFFERENCE'
        converters - select_converters(group2_query, graph)
      else
        converters
    end
  end

  def select_converters(query, graph = nil)
    parser = SelectStringParser.new(query)

    converters = []
    converters << parser.converter_keys.map{|key| graph.converter(key) }
    converters << parser.sector_keys.map{|key| graph.sector_converters(key) }
    converters << parser.group_keys.map{|key| graph.group_converters(key) }
    converters = converters.flatten.compact.uniq

    Rails.logger.warn("GQL: No Converters found for #{query}") if converters.empty?

    converters
  end

  # Takes a select string and extracts converter-keys or -ids and sector keys
  # s = SelectStringParser.new('sector_xyz_AND_some_converter_key_AND_3')
  # s.converter_keys
  # => ['some_converter', 3]
  # s.sector_keys
  # => ['xyz']
  #
  # Note: if a converter_key is numeric, it gets converted to an integer
  class SelectStringParser
    AND = '_AND_'

    def initialize(str)
      @keys = str.split(AND)
    end

    def converter_keys
      @keys.reject{|key| key[/^sector_(\w*)$/]}.
        map{|key| key.to_i > 0 ? key.to_i : key }
    end

    def group_keys
      @keys.map{|key| key[/^group_(\w*)$/,1]}.compact
    end

    def sector_keys
      @keys.map{|key| key[/^sector_(\w*)$/,1]}.compact
    end
  end
end

