module Gql::QueryInterface::Lookup

  def update_object
    @update_object
  end

  def update_object=(object)
    @update_object = object
  end

  def update_collection
    @update_collection
  end

  def update_collection=(col)
    @update_collection = col
  end

  def big_decimal(n)
    BigDecimal(n, exception: false) || n.to_f
  end

  def scenario
    @gql.scenario
  end

  def present?
    graph.present?
  end

  # @param [String] Graph API Method.
  # @return [Float]
  #
  def graph_query(key)
    key.nil? ? graph : graph.query(key)
  end

  # @param [String] Area attribute. E.g. areable_land
  # @return [Float]
  #
  def area(key)
    graph.area.send(key)
  end

  def all_nodes
    graph.nodes
  end

  # @param [String] Carrier key
  # @return [Carrier]
  #
  def carriers(keys)
    if keys.is_a?(Array)
      flatten_compact keys.map{|key| graph.carrier(key.to_sym) }
    else
      flatten_compact graph.carrier(keys.to_sym)
    end
  end

  # @param [String,Array] Use keys
  # @return [Node]
  #
  def use_nodes(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.use_nodes(key) }
    else
      flatten_compact graph.use_nodes(key)
    end
  end

  # @param [String,Array] Sector keys
  # @return [Node]
  #
  def sector_nodes(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.sector_nodes(key) }
    else
      flatten_compact graph.sector_nodes(keys)
    end
  end

  # @param [String,Array] Group keys
  # @return [Node]
  #
  def group_nodes(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.group_nodes(key) }
    else
      flatten_compact graph.group_nodes(keys)
    end
  end

  # @param [String] Node keys
  # @return [Node]
  #
  def nodes(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.node(key) }
    else
      flatten_compact [graph.node(keys)]
    end
  end

  # @param [String,Array] Group keys
  # @return [Array<Edge>]
  #
  def group_edges(keys)
    # Array(keys).map(&graph.method(:group_edges))
    if keys.is_a?(Array)
      flatten_compact(keys.flatten.map{|key| graph.group_edges(key) })
    else
      flatten_compact graph.group_edge(keys)
    end
  end

  def flatten_compact(val)
    val.flatten!
    val.compact!
    val
  end
end
