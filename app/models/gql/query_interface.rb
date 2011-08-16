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
  # e.g. GqueryCache and GqueryMemoizedSubqueries.
  include Base
  include GraphApi

  attr_accessor :graph

  def initialize(graph)
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
