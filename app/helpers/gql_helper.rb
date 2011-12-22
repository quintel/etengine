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

  def converter(key, period = :present)
    graph(period).converter(key)
  end

  def carriers(period = :present)
    graph(period).converters
  end

  def converters(period = :present)
    graph(period).converters
  end

  def carrier(key, period = :present)
    graph(period).carrier(key)
  end

end