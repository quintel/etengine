module Gql

##
#
# NEVER EVER! change @graph directly like @graph =. Always change it like self.graph= 
# Because we have optimizations when changing graphs
#
#
#
#
class QueryInterface

  # The implementation of #query, #subquery is done in GqueryBase,
  # so that we can extend it with caching strategies defined in
  # e.g. GqueryCache and GqueryMemoizedSubqueries.
  include Base
  include GraphApi

  def initialize(graph)
    self.graph = graph
  end

  ##
  # The currently active graph (present or future)
  #
  def graph
    @graph
  end

  ##
  # Sets the currently active graph (present or future)
  #
  def graph=(graph)
    @graph = graph
  end

  def graph_id
    graph.graph_id
  end

  def graph_year
    graph.year
  end

  def dataset_id
    graph.dataset.id
  end

  # Following includes are responsible for caching of queries
  # The order of includes is important.
  #
  # calling #subquery:
  # GqueryMemoizedSubqueries#subquery
  #   returns subquery when memoized, if not:
  #   (we can memoize results of future graph, because after the request, the memoization is lost)
  # GqueryCache#subquery
  #   returns memcached result of subquery for present graph, if not memcached:
  #   (we don't want to persistently cache the future graph as the results always change)
  # GqueryBase#subquery
  #   Executes the subquery
  #
  include GqueryCache # optional
  include MemoizedSubqueries # optional


end


end
