##
# GqueryGraphApi is the access point for the currently evaluated graph.
# It is used by the GqlQueryGrammar.
#
#
#
module Gql::Gquery::GraphApi
  ##
  # The currently active graph (present or future)
  #
  def graph
    @graph
  end

  def graph_id
    graph.graph_id
  end

  def dataset_id
    graph.dataset.id
  end

  def graph_year
    graph.year
  end

  ##
  # Sets the currently active graph (present or future)
  #
  def graph=(graph)
    @graph = graph
  end

  ##
  # @param [String] Graph API Method.
  # @return [Float]
  #
  def graph_query(key)
    graph.query.send(key)
  end

  ##
  # @param [String] Area attribute. E.g. areable_land
  # @return [Float]
  #
  def area(key)
    graph.area.send(key)
  end

  def all_converters
    graph.converters#.map(&:query)
  end

  ##
  # @param [String] Carrier key
  # @return [Carrier]
  #
  def carriers(keys)
    flatten_compact [keys].flatten.map{|key| graph.carrier(key.to_sym) }
  end

  ##
  # @param [String] Use keys
  # @return [Converter]
  #
  def use_converters(keys)
    flatten_compact [keys].flatten.map{|key| graph.use_converters(key) }
  end

  ##
  # @param [String] Sector keys
  # @return [Converter]
  #
  def sector_converters(keys)
    flatten_compact [keys].flatten.map{|key| graph.sector_converters(key) }
  end

  ##
  # @param [String] Group keys
  # @return [Converter]
  #
  def group_converters(keys)
    flatten_compact [keys].flatten.map{|key| graph.group_converters(key) }
  end

  ##
  # @param [String] Converter keys
  # @return [Converter]
  #
  def converters(keys)
    flatten_compact [keys].flatten.map{|key| graph.converter(key) }
  end

  def flatten_compact(val)
    val.flatten!
    val.compact!
    val
  end
end
