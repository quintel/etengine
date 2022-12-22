class ScenarioUpdateSerializer
  def initialize(controller, updater, params)
    @controller = controller
    @updater = updater
    @requested_queries = params[:gqueries] || []

    @errors  = []
    @results = {}

    if @requested_queries.any? && assert_valid_gqueries! && @updater.errors.empty?
      @results = perform_gqueries!
    end
  end

  # The scenario update and query results ready for JSON.
  #
  # @return [Hash]
  #
  def as_json(*)
    serializer = ScenarioSerializer.new(@controller, @updater.scenario)
    { scenario: serializer, gqueries: @results }
  end

  # Returns all of the errors with the user request. For interop with the
  # Rails Responder.
  #
  # @return [Array<String>]
  #
  def errors
    @updater.errors.messages.values.flatten + @errors
  end

  #######
  private
  #######

  # Returns an array of Gquery objects which the user has requested to be
  # performed.
  #
  # @return [Array<Gquery>]
  #
  def queries
    @requested_queries.map { |key| Gquery.get(key) }.compact
  end

  # Checks each of the gquery keys requested by the user, and asserts that
  # the query exists. Adds messages to the errors object and returns false
  # if a query is not present.
  #
  # @return [true, false]

  def assert_valid_gqueries!
    return true if queries.length == @requested_queries.length

    (@requested_queries - queries.map(&:key)).each do |key|
      @errors.push("Gquery #{ key } does not exist")
    end

    false
  end

  # Performs the queries requested. Adds messages to the errors object if
  # one or more queries fail.
  #
  # @return [Hash{String => Array<Numeric>}]
  #
  def perform_gqueries!
    gql = @updater.scenario.gql

    queries.each_with_object({}) do |query, results|
      unless query.api_allowed?
        @errors.push("#{query.key} may not be requested via the API")
        next
      end

      present = perform_query(gql, :present, query)
      future  = perform_query(gql, :future,  query)

      results[query.key] = {
        present: present, future: future, unit: query.unit
      }
    end
  end

  # Performs an individual query.
  #
  # @param [Gql::Gql] gql    The graph to be queries.
  # @param [Symbol]   period One of :present or :future
  # @param [Gquery]   query  The query to be performed.
  #
  # @return [Numeric, false]
  #   Returns the query result, or nil if there was an error. Some gqueries
  #  return boolean values, so false must be preserved
  #
  def perform_query(gql, period, query)
    behavior = query.behavior

    return behavior.fallback_value unless behavior.period_supported?(period)

    value = gql.public_send(:"query_#{ period }", query)

    # Rails 4.1 JSON encodes BigDecimal as a string. This is not part of
    # the ETEngine APIv3 spec.
    value = value.to_f if value.is_a?(BigDecimal)

    behavior.process_result(nan?(value) ? 0.0 : value)
  rescue Exception => exception
    # TODO Exception is *way* too low level to be rescued; we could do
    #      with a GraphError exception for "acceptable" graph errors.
    @errors.push("#{ query.key }/#{ period } - #{ exception.message } | " \
                  "#{ exception.backtrace.join("\n") }")
    nil
  end

  # Internal: Tests if a value NaN.
  #
  # Returns true or false.
  def nan?(value)
    value.is_a?(Float) && value.nan?
  end

end
