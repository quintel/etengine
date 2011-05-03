##
# Default Query implementation of Gquery.
# Can be extended by other caching algorithms. (see GqueryCache)
#
# Usage:
# query = Gql::Gquery.new()
# query.query_graph(future_graph, "Q ( electricity_production ) ")
# Or:
# query.query("Q ( electricity_production ) ")
#
module Gql::GqueryBase
  ##
  #
  #
  # @param query [String] An (unescaped) gquery
  # @param graph [Qernel::Graph] The Qernel::Graph to be queried
  # @return result
  #
  def query_graph(query, graph)
    self.graph = graph
    result = self.query(query)
    return result
#  rescue Exception => e
#    raise Gql::GqlError.new("Gql::Gquery.query_graph exception for query: #{query}. #{e}")
  end

  def scope
    self
  end

  def debug_graph(query_string, graph)
    self.graph = graph
    if parsed = clean_and_parse(query_string)
      msg = []
      parsed.debug(scope, msg)
      @graph = nil
      msg
    else
      @graph = nil
      raise Gql::GqlError.new("Gql::Gquery.query query is not valid: #{clean(query_string)}.")
    end
  end

  ##
  #
  # @param query_string [String] Excaped query_string
  # @return [Float]
  # @raise [Gql::GqlError] if query is not valid.
  #
  def query(query_string)
    if parsed = clean_and_parse(query_string)
      parsed.result(scope)
    else
      raise Gql::GqlError.new("Gql::Gquery.query query is not valid: #{clean(query_string)}.")
    end
  end


  ##
  # Is the given gquery_string valid?
  #
  def check(query)
    Gql::GqueryCleanerParser.check_query(query)
  end

  ##
  # A subquery is a call to another query.
  # e.g. "SUM(QUERY(foo))"
  #
  def subquery(gquery_key)
    # subquery should not set or reset the graph_for_grammar.
    # It is a subquery of a #query, so it should still use the same
    # graph_for_grammar.
    if gquery = ::Gquery.get(gquery_key)
      gquery.parsed_query.andand.result(scope)
    else
      nil
    end
  end

  private

  def clean(query_string)
    Gql::GqueryCleanerParser.clean(query_string)
  end

  def clean_and_parse(query_string)
    Gql::GqueryCleanerParser.clean_and_parse(query_string)
  end


end
