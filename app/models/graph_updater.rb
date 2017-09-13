module GraphUpdater
  def self.call(graph, method, args)
    case method
    when 'preset_demand_setter'     then preset_demand_setter(graph, *args)
    when 'demand_setter'            then demand_setter(graph, *args)
    when 'share_setter'             then share_setter(graph, *args)
    when 'conversion_setter'        then conversion_setter(graph, *args)
    when 'reserved_fraction_setter' then reserved_fraction_setter(graph, *args)
    when 'number_of_units_setter'   then set_unit(graph, *args)
    else
      raise ArgumentError, "no such method to update the graph #{ method }"
    end
  end

  def self.preset_demand_setter(graph, node_name, value)
    node = graph.converter(node_name)

    node.preset_demand = value
  end

  def self.demand_setter(graph, node_name, value)
    node = graph.converter(node_name)

    node.demand = value
  end

  def self.share_setter(graph, edge_name, value)
    link = graph.link(edge_name)

    link.share = value
  end

  def self.conversion_setter(graph, slot_name, value)
    node_name, carrier = slot_name.to_s.split('@')

    node = graph.converter(node_name)
    slot = node.slots.detect{ |s| s.carrier.key == carrier.to_sym }

    slot.conversion = value
  end

  def self.reserved_fraction_setter(graph, node_name, value)
    node = graph.converter(node_name)

    node.converter_api.reserved_fraction = value
  end

  def self.set_unit(graph, node_name, value)
    node = graph.converter(node_name)

    node.number_of_units = value
  end
end
