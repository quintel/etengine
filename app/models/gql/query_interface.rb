module Gql

# The QueryInterface takes a gquery object (or a raw gql query string) 
# and runs it on  the selected graph.
#
#    graph = Qernel::GraphParser.new("lft(100) == s(1.0) ==> rgt").build
#    graph.calculate
#
#    q = Gql::QueryInterface.new( graph )
#    q.query( Gquery.first )
#    q.query("V(lft; demand)")
#    
#
class QueryInterface

  # The implementation of #query, #subquery is done in GqueryBase,
  # so that we can extend it with caching strategies defined in
  # e.g. QueryCache and GqueryMemoizedSubqueries.
  include Base
  include GraphApi

  attr_accessor :graph
  attr_reader :options

  # @param [Hash] options 
  # @option options [Boolean] :cache_prefix (nil) 
  #   Set a prefix for the cache key. Changing the prefix will invalidate the caches.
  #   Use this wisely. E.g. for the present graph, the graph.id is recommended over 
  #   scenario.id (as present graphs are the same in all scenarios).
  #   If set to nil, false or not at all defined, query_cache will not be used.
  #
  def initialize(graph, options = {})
    @graph = graph
    @options = options
  end

  # Following includes are responsible for caching of queries
  # The order of includes is important.
  #
  # calling #subquery:
  # QueryMemoization#subquery
  #   returns subquery when memoized, if not:
  #   (we can memoize results of future graph, because after the request, the memoization is lost)
  # QueryCache#subquery
  #   returns memcached result of subquery for present graph, if not memcached:
  #   (we don't want to persistently cache the future graph as the results always change)
  # GqueryBase#subquery
  #   Executes the subquery
  #
  include QueryCache # optional
  include QueryMemoization # optional


end


end
