module Gql::QueryInterface::Base
  GQL3 = true

  def input_value
    @input_value
  end

  def input_value=(val)
    @input_value = val
  end

  def scope
    self
  end

  # Figures out the kind of query and executes it
  #
  # @param [String, Gquery] query Escaped query_string
  # @param [String] input_value user value from param
  # @return [Float]
  # @raise [Gql::GqlError] if query is not valid.
  #
  def query(obj, input_value = nil)
    self.input_value = input_value.to_s
    if obj.is_a?(Gquery)
      execute_gquery_key(obj.key)
    elsif obj.is_a?(Input)
      self.input_value = "#{self.input_value}#{obj.v1_legacy_unit}" unless self.input_value.include?('%')
      execute_input(Gql::QueryInterface::Preparser.new(obj.query).parsed)
    elsif obj.is_a?(String) 
      # pure GQL string
      GQL3 ? @rubel.query(obj) : execute_parsed_query(Gql::QueryInterface::Preparser.new(obj).parsed)
    else
      raise Gql::GqlError.new("Gql::QueryInterface.query query is not valid: #{clean(obj)}.")
    end
  ensure
    self.input_value = nil
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
      #ActiveSupport::Notifications.instrument("gql.query.custom: #{gquery_key}") do
        GQL3 ? @rubel.query(gquery.query_sanitized) : execute_parsed_query(gquery.parsed_query)
      #end
    else
      nil
    end
  end
  alias execute_gquery_key subquery


  def execute_input(parsed_query)
    parsed_query.result(scope)
  rescue => e
    raise Gql::GqlError.new("UPDATE: #{parsed_query.text_value}:\n #{e.inspect}")
  end

  def execute_parsed_query(parsed_query)
    # HACK: In case no gql was assigned (this happens often in old specs)
    # do not prepare. Thus gql &&.
    gql.prepare if gql && !gql.calculated?
    
    parsed_query.result(scope)
  rescue => e
    raise Gql::GqlError.new("Query: #{parsed_query.text_value}.\n #{e.inspect}")
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
