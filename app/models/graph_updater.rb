module GraphUpdater
  def self.call(graph, method, args)
    case method
    when 'share_setter'  then share_setter(graph, *args)
    when 'demand_setter' then demand_setter(graph, *args)
    when 'unit_setter'   then set_unit(graph, *args)
    else
      raise ArgumentError, "no such method to update the graph #{ method }"
    end
  end

  def self.demand_setter(graph, node_name, value)
    node = graph.converter(node_name)

    node.preset_demand = value
  end

  def self.share_setter(graph, edge_name, value)
    link = graph.link(edge_name)

    link.share = value
  end

  def self.set_unit(graph, node_name, value)
    node = graph.converter(node_name)

    node.number_of_units = value
  end
end
