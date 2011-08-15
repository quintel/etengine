module Gql
##
# GqueryMemoizedSubqueries memoizes subquery calls for future and present graphs.
#
module QueryInterface::MemoizedSubqueries

  ##
  # Subqueries are memoized, so that if a subquery is called twice, we save performance.
  #
  def subquery(gquery_key)
    if gquery_key.is_a?(::Gquery)
      gquery = gquery_key
    else
      gquery = ::Gquery.get(gquery_key)
    end

    @memoized_subquery ||= {}

    # we cannot use normal memoization, as some gqueries return a boolean (notably peak load)
    if @memoized_subqueries.has_key?(gquery_key)
      @memoized_subqueries[gquery_key]
    else
      @memoized_subqueries[gquery_key] = super(gquery_key)
    end
  end

end

end
