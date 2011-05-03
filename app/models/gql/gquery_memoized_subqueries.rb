module Gql
##
# GqueryMemoizedSubqueries memoizes subquery calls for future and present graphs.
#
module GqueryMemoizedSubqueries

  def graph=(graph)
    @graph = graph
    @graph_cache_key = scope_memoized_key
    @graph
  end

  def scope_memoized_key
    :"subquery_#{scope.dataset_id}_#{scope.graph_year}"
  end

  def graph_cache_key
    raise "@graph_cache_key undefined. something went wrong. check if GqueryMemoizedSubqueries#graph= works" unless @graph_cache_key
    @graph_cache_key
  end

  ##
  # Subqueries are memoized, so that if a subquery is called twice, we save performance.
  #
  def subquery(gquery_key)
    graph_key = graph_cache_key
    @memoized_subquery ||= {}
    memoized_subqueries = @memoized_subquery[graph_key] ||= {}

    # we cannot use normal memoization, as some gqueries return a boolean (notably peak load)
    if memoized_subqueries.has_key?(gquery_key)
      memoized_subqueries[gquery_key]
    else
      memoized_subqueries[gquery_key] = super(gquery_key)
    end
  end

end

end
