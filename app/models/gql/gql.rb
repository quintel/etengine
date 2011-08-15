# helper method for irb
def gql(query)
  Current.gql.query(query)
end

# DEBT: debug_present/future query_present/future and query_interface should be refactored.
#
module Gql
##
# GQL (Graph Query Language) is to a Graph/Qernel what SQL is to a database.
#
# It is responsible to update the future graph with user values/assumptions
# and to query the present and future graph using GQL Queries (Gquery).
#
# A Gql instance holds a present and a future graph. The present graph should
# not change at all (the exception are after_calculation_updates for dynamic
# values such as the price for gasmix). The future graph gets updated with user
# values.
#
# == Useage
#
#   graph = Graph.find( 1 )     # the graph we want to query
#   gql = Gql::Gql.new( graph ) # Create Gql instance for 'graph'
#   gql.prepare_graphs          # updates and calculates graphs based on user assumptions
#
#   res = gql.query("SUM(1.0,2.0)")
#   # => <Gql::GqueryResult present_value:3.0 future_value:3.0 present_year:2010 future_year:2040>
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
# === GqueryResult
#
# ResultSet of a Gquery.
#
# === Policy
#
# Policy now follows the convention that target values are always absolute values, whereas
# user inputs can be, for example, a percent increase. The rules to transform user inputs
# to absolute targets are encapsulated in PolicyGoal#target_value, so that GOAL(policy)
# queries and stored procedures (to support OutputElement rendering) have a uniform interface.
#
#
class Gql
  extend ActiveModel::Naming

  include UpdatingConverter
  include Selecting

  # @return [Qernel::Graph]
  attr_reader :present_interface
  # @return [Qernel::Graph]
  attr_reader :future_interface

  ##
  # assigns, updates and calculates present and future graph upon initializing
  #
  # @param present [Qernel::Graph] Graph for present
  # @param future [Qernel::Graph] Graph for future scenario. Gets updated with Current.scenario.update_statements
  #
  def initialize(graph_model)
    # The if is a temporary solution.
    # I added this so that testing/stubbing/mocking gets easier (seb 2010-10-11)
    return if graph_model == :testing

    @present = graph_model.present
    @future = graph_model.future

    @present.year = Current.scenario.start_year
    @future.year = Current.scenario.end_year

    @present_interface = ::Gql::QueryInterface.new(@present)
    @future_interface = ::Gql::QueryInterface.new(@future)
  end

  def present_graph
    @present_interface.graph
  end

  def future_graph
    @future_interface.graph
  end

  def present
    present_graph
  end

  def future
    future_graph
  end

  ##
  # Are the graphs calculated? If true, prevent the programmers
  # to add further update statements ({Scenario#add_update_statements}). 
  # Because they won't affect the system anymore.
  #
  # @return [Boolean]
  #
  def calculated?
    @calculated == true
  end

  ##
  # @return [Policy]
  #
  def policy
    @policy ||= Policy.new(@present, @future)
  end

  def benchmark(title)
    ::Graph.benchmark("Benchmark::Gql:: #{title}") do
      yield
    end
  end

  ##
  # Updates and calculates the graphs
  #
  # @return [Gql] Returns self, so that we can gql = Gql.new(graph).prepare_graphs
  #
  def prepare_graphs
    update_statements = Current.scenario.update_statements

    if update_statements
      update_time_curves(future_graph)      
      update_carriers(future_graph, update_statements['carriers'])
      update_area_data(future_graph, update_statements['area'])
      update_converters(future_graph, update_statements['converters'])
    end

    benchmark("calculate future") do
      future_graph.calculate
    end

    update_policies(update_statements['policies']) if update_statements

    # At this point the gql is calculated. Changes through update statements
    # should no longer be allowed, as they won't have an impact on the 
    # calculation (even though updating prices would work).
    @calculated = true  

    after_calculation_updates(present_graph)
    after_calculation_updates(future_graph)
    self
  end

  ##
  # Query the GQL, takes care of gql modifier strings.
  #
  # For performance reason it is suggested to pass a Gquery for 'query'
  # object rather than it's Gquery#query. Because parsing a gql statement
  # takes rather long time.
  #
  # @param query [String, Gquery] the single query.
  # @return [GqueryResult] Result query, depending on its gql_modifier
  #
  def query(gquery_or_string)
    if gquery_or_string.is_a?(::Gquery)
      modifier = gquery_or_string.gql_modifier
      query = gquery_or_string
    elsif gquery_or_string.is_a?(String)
      query, modifier = gquery_or_string.split(':').reverse
    end
    
    if modifier.nil?
      query_standard(query)
    elsif ::Gquery::GQL_MODIFIERS.include?(modifier.strip)
      send("query_#{modifier}", query)
    end
  end

private

  # Standard query without modifiers. Queries present and future graph.
  #
  # @param query [String, Gquery] the single query.
  # @return [GqueryResult] Result query, depending on its gql_modifier
  #
  def query_standard(query)
    GqueryResult.create [
      [Current.scenario.start_year, query_present(query)],
      [Current.scenario.end_year, query_future(query)]
    ]
  end

  ##
  # @param query [String] The query
  # @return [Float] The result of the present graph
  #
  def query_present(query)
    present_interface.query_graph(query)
  end

  ##
  # @param query [String] The query
  # @return [Float] The result of the future graph
  #
  def query_future(query)
    future_interface.query_graph(query)
  end

  ##
  # @param query [String] The query
  # @return [Float] The result of a historic serie, this values are db values not qernel.
  #
  def query_historic(query)
    historic_serie = HistoricSerie.find_by_key_and_area_code(query,Current.scenario.region)
    if historic_serie
      historic_serie.year_values.map{|h| [h.year,h.value]}
    else
      false
    end
  end

  ##
  # Not called directly. Use #query instead, e.g.:
  #
  #   gql.query("stored.foo_bar")
  #
  #
  # @param query [String] Calls a stored procedure
  # @return [GqueryResult] The result of the stored procedure
  #
  def query_stored(query)
    StoredProcedure.execute(query)
  end


end

end

