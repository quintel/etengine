module Gql
# GQL (Graph Query Language) is to a Graph/Qernel what SQL is to a database.
#
# It is responsible to update the future graph with user values/assumptions
# and to query the present and future graph using GQL Queries (Gquery).
#
# == Useage
#
#   graph = Graph.find( 1 )     # the graph we want to query
#   gql = Gql::Gql.new( graph ) # Create Gql instance for 'graph'
#   gql.prepare          # updates and calculates graphs based on user assumptions
#
#   res = gql.query("SUM(1.0,2.0)")
#   # => <Gql::ResultSet present_value:3.0 future_value:3.0 present_year:2010 future_year:2040>
#
#   gql.query_present("SUM(1,0,2.0)") # only get the present value
#   # => 3.0
#   gql.query_future("SUM(1,0,2.0)") # only get the future value
#   # => 3.0
#
# Within the project you can simply use:
#
#   Current.gql.query(...)
#
# == Components
#
# === Updating
#
# Updates the future graph with user assumptions. Uses the command pattern
# for specific update actions. Needs some smart thinking to clean up further.
#
# === Gquery
#
# Executes a (GQL 2) query and takes care of caching and subquery lookups.
#
# === GqlQueryParser
#
# The grammar of a GQL Query, defined using treetop gem.
# - gql_query.treetop which generates the GqlQueryParser during runtime
# (by requiring it in environment.rb).
# - GqlGquerySyntaxNode: Defines and implements all the functions of a Query.
#
# === StoredProcedure
#
# Queries that cannot be solved by using GQL queries.
# To query a StoredProcedure#foo_bar use:
# Current.gql.query('stored.foo_bar')
#
# === ResultSet
#
# ResultSet of a Gquery.
#
class Gql
  extend ActiveModel::Naming

  ENABLE_QUERY_CACHE_FOR_FUTURE = true

  attr_reader :graph_model

  def initialize(graph_model)
    # The if is a temporary solution.
    # I added this so that testing/stubbing/mocking gets easier (seb 2010-10-11)
    return if graph_model == :testing

    @graph_model = graph_model
  end

  def scenario
    Current.scenario
  end

  # @return [Qernel::Graph]
  #
  def present_graph
    @present_graph ||= graph_model.present.tap{|g| g.year = scenario.start_year}
  end

  # @return [Qernel::Graph]
  #
  def future_graph
    @future_graph ||= graph_model.future.tap{|g| g.year = scenario.end_year}
  end

  # @return [QueryInterface]
  #
  def present
    @present ||= QueryInterface.new(present_graph, :cache_prefix => "#{scenario.id}-present-#{scenario.present_updated_at}")
  end

  # @return [QueryInterface]
  #
  def future
    @future ||= if ENABLE_QUERY_CACHE_FOR_FUTURE && !scenario.test_scenario?
      QueryInterface.new(future_graph, :cache_prefix => "#{scenario.id}-#{scenario.updated_at}")
    else
      QueryInterface.new(future_graph)
    end
  end

  # Are the graphs calculated? If true, prevent the programmers
  # to add further update statements ({Scenario#add_update_statements}). 
  # Because they won't affect the system anymore.
  #
  # @return [Boolean]
  #
  def calculated?
    @calculated == true
  end

  # Query the GQL, takes care of gql modifier strings.
  #
  # For performance reason it is suggested to pass a Gquery for 'query'
  # object rather than it's Gquery#query. Because parsing a gql statement
  # takes rather long time.
  #
  #     gql.query(Gquery.first) 
  #     gql.query("SUM(1.0, 2.0)")         # => [[2010, 3.0],[2040,3.0]]
  #     gql.query("present:SUM(1.0, 2.0)") # => 3.0
  #
  # @param query [String, Gquery] the single query.
  # @param rescue_resultset [ResultSet] A ResultSet that is return in case of errors.
  # @return [ResultSet] Result query, depending on its gql_modifier
  #
  def query(gquery_or_string, rescue_with = nil)
    if gquery_or_string.is_a?(::Gquery)
      modifier = gquery_or_string.gql_modifier
      query = gquery_or_string
    elsif gquery_or_string.is_a?(String)
      query, modifier = gquery_or_string.split(':').reverse
    end
    
    if modifier.nil?
      query_standard(query)
    elsif Gquery::GQL_MODIFIERS.include?(modifier.strip)
      send("query_#{modifier}", query)
    end
  rescue => e
    if rescue_with == :debug
      ResultSet.create([[2010, e.inspect], [2040, e.inspect]])
    elsif rescue_with == :airbrake
      # TODO: something's broken here with airbrake 3.0.5:
      # undefined method `backtrace' for #<Hash:0x007fda54900b88> ?!
      # https://github.com/airbrake/airbrake/issues/19
      Airbrake.notify(:error_message => e.message, :backtrace => caller)
      ResultSet::INVALID
    elsif rescue_with.present?
      rescue_with
    else
      raise e unless rescue_with
    end
  end

  # Updates and calculates the graphs
  #
  def prepare
    # 2011-08-15: the present has to be prepared first. otherwise 
    # updating the future won't work (we need the present values)

    prepare_present
    prepare_future

    ActiveSupport::Notifications.instrument("gql.performance.graph.calculate #{present_graph.year}") do
      present_graph.calculate
    end
    ActiveSupport::Notifications.instrument("gql.performance.graph.calculate #{future_graph.year}") do
      future_graph.calculate
    end

    # At this point the gql is calculated. Changes through update statements
    # should no longer be allowed, as they won't have an impact on the 
    # calculation (even though updating prices would work).
    @calculated = true
  end

  def prepare_present
    ActiveSupport::Notifications.instrument('gql.performance.graph.prepare_present') do
      # DEBT wrong. check for present_updated_at!!
      if scenario.update_statements_present.empty? && scenario.inputs_present.empty?
        present_graph.dataset ||= graph_model.calculated_present_data
      else
        present_graph.dataset ||= graph_model.dataset.to_qernel
        UpdateInterface::Graph.new(present_graph).update_with(scenario.update_statements_present)
        scenario.inputs_present.each do |input, value|
          present.query(input, value)
        end
      end
    end
  end

  def prepare_future
    ActiveSupport::Notifications.instrument('gql.performance.graph.prepare_future') do
      if Rails.env.test?
        future_graph.dataset ||= graph_model.dataset.to_qernel
      else
        future_graph.dataset = graph_model.dataset.to_qernel
      end
      scenario.inputs_before.each do |input, value|
        future.query(input, value)
      end
      UpdateInterface::Graph.new(future_graph).update_with(scenario.update_statements)
      scenario.inputs_future.each do |input, value|
        future.query(input, value)
      end
    end
  end

  # Runs an array of gqueries. The gquery list might be expressed in all the formats accepted
  # by Gquery#get, ie key or id
  # 
  # @param [Array<String>]
  # @return [Hash<String => ResultSet>]
  #
  def query_multiple(gquery_keys)
    gquery_keys = gquery_keys - ["null", "undefined"]

    rescue_with = :airbrake
    gquery_keys.inject({}) do |hsh, key|
      result = if gquery = (Gquery.get(key) rescue nil) and !gquery.converters?
        query(gquery, rescue_with)
      else
        key.include?('(') ? query(key, rescue_with) : rescue_with
      end
      hsh.merge! key => result
      hsh
    end
  end

protected

  # Standard query without modifiers. Queries present and future graph.
  #
  # @param query [String, Gquery] the single query.
  # @return [ResultSet] Result query, depending on its gql_modifier
  #
  def query_standard(query)
    ResultSet.create [
      [scenario.start_year, query_present(query)],
      [scenario.end_year, query_future(query)]
    ]
  end

  # @param query [String] The query
  # @return [Float] The result of the present graph
  #
  def query_present(query)
    present.query(query)
  end

  # @param query [String] The query
  # @return [Float] The result of the future graph
  #
  def query_future(query)
    future.query(query)
  end

  # @param query [String] The query
  # @return [Float] The result of a historic serie, this values are db values not qernel.
  #
  def query_historic(query)
    historic_serie = HistoricSerie.find_by_key_and_area_code(query, scenario.region)
    if historic_serie
      historic_serie.year_values.map{|h| [h.year,h.value]}
    else
      false
    end
  end

  # Not called directly. Use #query instead, e.g.:
  #
  #   gql.query("stored.foo_bar")
  #
  # @param query [String] Calls a stored procedure
  # @return [ResultSet] The result of the stored procedure
  #
  def query_stored(query)
    StoredProcedure.execute(query)
  end  
end

end

