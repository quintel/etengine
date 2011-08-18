module Gql::QueryInterface::Base

  def user_input
    @user_input
  end

  def user_input=(val)
    @user_input = val
  end

  def scope
    self
  end

  # @param query [String, Gquery] Escaped query_string
  # @return [Float]
  # @raise [Gql::GqlError] if query is not valid.
  #
  def query(obj, user_input = nil)
    self.user_input = user_input
    if obj.is_a?(Gquery)
      subquery(obj.key)
    elsif obj.is_a?(Input)
      result_of_parsed_query(Gql::QueryInterface::Preparser.new(obj.query).parsed, false)
    elsif parsed = Gql::QueryInterface::Preparser.new(obj).parsed
      result_of_parsed_query(parsed)
    else
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(obj)}.")
    end
  ensure
    self.user_input = nil
  end

  # @return [Array<String>] Debug messages
  #
  def debug(query_string)
    if parsed = Gql::QueryInterface::Preparser.new(query_string).parsed
      msg = []
      parsed.debug(scope, msg)
      msg
    else
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(query_string)}.")
    end
  rescue => e
    e.inspect # return the error message as a string
  end

  # Is the given gquery_string valid?
  #
  def check(query)
    Gql::QueryInterface::Preparser.new(query).valid?
  end

  # A subquery is a call to another query.
  # e.g. "SUM(QUERY(foo))"
  #
  def subquery(gquery_key)
    if gquery = get_gquery(gquery_key)
      result_of_parsed_query(gquery.parsed_query)
    else
      nil
    end
  end

protected

  def result_of_parsed_query(parsed_query, check_if_calculated = true)
    # DEBT: decouple from Current.gql
    #       maybe add a Observer to graph:
    #       in gql: present_graph.observe_calculate(Current.gql)
    #       here:   present_graph.notify_observers!
    #
    Current.gql.prepare if check_if_calculated && !Current.gql.calculated?
    
    parsed_query.result(scope)
  end

  def get_gquery(gquery_or_key)
    if gquery_or_key.is_a?(::Gquery)
      gquery_or_key
    else
      ::Gquery.get(gquery_or_key)
    end
  end

  def clean(query_string)
    Gql::QueryInterface::Preparser.new(query_string).clean
  end



end
