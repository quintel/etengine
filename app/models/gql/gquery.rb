module Gql
##
#
# NEVER EVER! change @graph directly like @graph =. Always change it like self.graph= 
# Because we have optimizations when changing graphs
#
#
#
#
class Gquery
  # The implementation of #query, #subquery is done in GqueryBase,
  # so that we can extend it with caching strategies defined in
  # e.g. GqueryCache and GqueryMemoizedSubqueries.
  include GqueryBase
  include GqueryGraphApi

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
  unless Rails.env.test?
    puts "WAARNING"
    # Do not memcache queries in testing. Otherwise we have a problem with the blackbox_spec
    #  As it uses the same graphs for testing different scenarios, so scenario 2 gets cached
    #  values from scenario 1. We could also implement better cache keys to circumvent that.
    include GqueryCache # optional
  end
  include GqueryMemoizedSubqueries # optional


end


end
