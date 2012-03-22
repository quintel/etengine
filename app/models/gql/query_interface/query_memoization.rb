module Gql
  # Memoize subquery calls.
  module QueryInterface::QueryMemoization
    # Subqueries are memoized, so that if a subquery is called twice, we save performance.
    #
    def subquery(gquery_key)
      @memoized_subqueries ||= {}

      # we cannot use normal memoization, as some gqueries return a boolean (notably peak load)
      if @memoized_subqueries.has_key?(gquery_key)
        @memoized_subqueries[gquery_key]
      else
        @memoized_subqueries[gquery_key] = super(gquery_key)
      end
    end
  end
end
