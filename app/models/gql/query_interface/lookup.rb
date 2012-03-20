##
# GqueryGraphApi is the access point for the currently evaluated graph.
# It is used by the GqlQueryGrammar.
#
#
#
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
    BigDecimal(n)
  end
  
  def scenario
    Current.scenario
  end

  # @param [String] Graph API Method.
  # @return [Float]
  #
  def graph_query(key)
    graph.query(key)
  end

  # @param [String] Area attribute. E.g. areable_land
  # @return [Float]
  #
  def area(key)
    graph.area.send(key)
  end

  def all_converters
    graph.converters
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
  # @return [Converter]
  #
  def use_converters(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.use_converters(key) }
    else
      flatten_compact graph.use_converters(key)
    end
  end

  # @param [String,Array] Sector keys
  # @return [Converter]
  #
  def sector_converters(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.sector_converters(key) }
    else
      flatten_compact graph.sector_converters(keys)
    end
  end

  # @param [String,Array] Group keys
  # @return [Converter]
  #
  def group_converters(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.group_converters(key) }
    else
      flatten_compact graph.group_converters(keys)
    end
  end

  # @param [String] Converter keys
  # @return [Converter]
  #
  def converters(keys)
    if keys.is_a?(Array)
      flatten_compact keys.flatten.map{|key| graph.converter(key) }
    else
      flatten_compact [graph.converter(keys)]
    end
  end

  def flatten_compact(val)
    val.flatten!
    val.compact!
    val
  end
end
