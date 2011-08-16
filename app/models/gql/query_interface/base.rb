module Gql::QueryInterface::Base

  def scope
    self
  end

  # @param query [String, Gquery] Escaped query_string
  # @return [Float]
  # @raise [Gql::GqlError] if query is not valid.
  #
  def query(query)
    if query.is_a?(::Gquery)
      subquery(query.key)
    elsif parsed = clean_and_parse(query)
      parsed.result(scope)
    else
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(query)}.")
    end
  end

  # @return [Array<String>] Debug messages
  #
  def debug(query_string)
    self.graph = graph unless graph.nil?
    if parsed = clean_and_parse(query_string)
      msg = []
      parsed.debug(scope, msg)
      @graph = nil
      msg
    else
      @graph = nil
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(query_string)}.")
    end
  rescue => e
    e.inspect
  end

  # Is the given gquery_string valid?
  #
  def check(query)
    Gql::QueryInterface::Preparser.check_query(query)
  end

  # A subquery is a call to another query.
  # e.g. "SUM(QUERY(foo))"
  #
  def subquery(gquery_key)
    if gquery = get_gquery(gquery_key)
      gquery.parsed_query.result(scope)
    else
      nil
    end
  end

protected

  def get_gquery(gquery_or_key)
    if gquery_or_key.is_a?(::Gquery)
      gquery_or_key
    else
      ::Gquery.get(gquery_or_key)
    end
  end

  def clean(query_string)
    Gql::QueryInterface::Preparser.clean(query_string)
  end

  def clean_and_parse(query_string)
    Gql::QueryInterface::Preparser.clean_and_parse(query_string)
  end


end
