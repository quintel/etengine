module GqlHelper
  def gql
    @gql
  end

  def graph(period)
    if period == :present
      gql.present_graph
    else
      gql.future_graph
    end
  end

  def gql_query(q)
    gql.query(q)
  end

  def node(key, period = :present)
    graph(period).node(key)
  end

  def carriers(period = :present)
    graph(period).nodes
  end

  def nodes(period = :present)
    graph(period).nodes
  end

  def carrier(key, period = :present)
    graph(period).carrier(key)
  end

end
