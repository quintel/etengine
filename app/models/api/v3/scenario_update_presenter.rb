module Api
  module V3
    class ScenarioUpdatePresenter
      def initialize(controller, updater, params)
        @controller = controller
        @updater = updater
        @requested_queries = params[:gqueries] || []
        @detailed = params[:detailed].present?

        @errors  = []
        @results = {}

        if assert_valid_gqueries!
          @results = perform_gqueries!
        end
      end

      # The scenario update and query results ready for JSON.
      #
      # @return [Hash]
      #
      def as_json(*)
        scenario_presenter = ScenarioPresenter.new(
          @controller, @updater.scenario, detailed: @detailed)

        { scenario: scenario_presenter, gqueries: @results }
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
      #
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

        queries.each_with_object(Hash.new) do |query, results|
          present = perform_query(gql, :present, query)
          future  = perform_query(gql, :future,  query)

          results[query.key] = {
            present: present, future: future, unit: query.unit
          }
        end
      rescue Exception => exception
        # An error while setting up the graph.
        @errors.push(([exception.message] + exception.backtrace).join("\n"))
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
        gql.public_send(:"query_#{ period }", query)
      rescue Exception => exception
        # TODO Exception is *way* too low level to be rescued; we could do
        #      with a GraphError exception for "acceptable" graph errors.
        @errors.push("#{ query.key }/#{ period } - #{ exception.message } | " \
                     "#{ exception.backtrace.join("\n") }")
        nil
      end

    end # ScenarioUpdatePresenter
  end # V3
end # Api
