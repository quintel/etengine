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
#   gql.query(...)
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
# === ResultSet
#
# ResultSet of a Gquery.
#
class Gql
  extend ActiveModel::Naming

  ENABLE_QUERY_CACHE_FOR_FUTURE = true

  attr_accessor :present_graph, :future_graph, :dataset, :scenario
  attr_reader :graph_model

  # @param [Graph] graph_model
  # @param [Dataset,String] dataset Dataset or String for country
  #
  def initialize(scenario)
    if scenario.is_a?(Scenario)
      @scenario = scenario
      loader    = Etsource::Loader.instance
      @present_graph = loader.graph.tap{|g| g.year = @scenario.start_year}
      @future_graph  = loader.graph.tap{|g| g.year = @scenario.end_year}
      @dataset = loader.dataset(@scenario.code)
    end
  end

  # @return [Qernel::Dataset] Dataset used for the present. Is calculated and cannot be updated anymore
  #
  def calculated_present_dataset
    marshal = Rails.cache.fetch("/datasets/#{scenario.id}/#{scenario.present_updated_at.to_i}/calculated_qernel") do
      graph = present_graph.tap{|g| g.dataset = dataset_clone }
      graph.calculate
      Marshal.dump(graph.dataset)
    end
    Marshal.load marshal
  end

  # @return [Qernel::Dataset] Dataset used for the future. Needs to be updated with user input and then calculated.
  #
  def dataset_clone
    ActiveSupport::Notifications.instrument("gql.performance.dataset_clone") do
      Marshal.load(Marshal.dump(@dataset))
    end
  end

  # @return [QueryInterface]
  #
  def present
    # Disable Caching of Gqueries until a smart solution has been found
    #
    #@present ||= QueryInterface.new(self, present_graph, :cache_prefix => "#{scenario.id}-present-#{scenario.present_updated_at}")
    @present ||= QueryInterface.new(self, present_graph)
  end

  # @return [QueryInterface]
  #
  def future
    # Disable Caching of Gqueries until a smart solution has been found
    #
    # @future ||= if ENABLE_QUERY_CACHE_FOR_FUTURE && !scenario.test_scenario?
    #   QueryInterface.new(self, future_graph, :cache_prefix => "#{scenario.id}-#{scenario.updated_at}")
    # else
    @future ||= QueryInterface.new(self, future_graph)
    # end
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
    elsif gquery_or_string.respond_to?(:call)
      query, modifier = gquery_or_string, nil
    end
    
    query_with_modifier(query, modifier)

  rescue => e
    if rescue_with == :debug
      ResultSet.create([[2010, e.inspect], [2040, e.inspect]])
    elsif rescue_with == :airbrake
      # TODO: This fails on offline setups. Convert to a notification
      # TODO: something's broken here with airbrake 3.0.5:
      # undefined method `backtrace' for #<Hash:0x007fda54900b88> ?!
      # https://github.com/airbrake/airbrake/issues/19
      Airbrake.notify(:error_message => e.message, :backtrace => caller) unless
        APP_CONFIG[:standalone]
      ResultSet::INVALID
    elsif rescue_with.present?
      rescue_with
    else
      raise e unless rescue_with
    end
  end


  # Run a query with the strategy defined in the parameter
  def query_with_modifier(query, strategy)
    key = query.respond_to?(:key) ? query.key : 'custom'
    ActiveSupport::Notifications.instrument("gql.query.#{key}.#{strategy}") do
      if strategy.nil?
        query_standard(query)
      elsif Gquery::GQL_MODIFIERS.include?(strategy.strip)
        send("query_#{strategy}", query)
      end
    end
  end

  # Connects datasets to a present and future graph.
  # Updates them with user inputs and calculates. 
  # After being prepared graphs are ready to be queried.
  # This method can only be prepared once.
  #
  # This method is "lazy-" called from a {Gql::QueryInterface} object, 
  # when there is no cached result for a Gquery. 
  #
  # When to prepare:
  # - For querying
  # - For working/inspecting the graph (e.g. from the command line)
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

  # Runs an array of gqueries. The gquery list might be expressed in all the formats accepted
  # by Gquery#get, ie key or id
  # 
  # @param [Array<String>]
  # @return [Hash<String => ResultSet>]
  #
  def query_multiple(gquery_keys)
    gquery_keys = gquery_keys - ["null", "undefined"]

    rescue_with = Rails.env.production? ? :airbrake : :debug
    gquery_keys.inject({}) do |hsh, key|
      result = if gquery = (Gquery.get(key) rescue nil) and !gquery.converters?
        query(gquery, rescue_with)
      else
        # Why this? Hmm. Seems like we only really want to execute if it's a Gql query
        #  (every gql query contains a "(" and ")"). If it represents a non-existing
        #  gquery key, then return rescue_with (which probably used to be a 'ERROR' earlier).
        key.include?('(') ? query(key, rescue_with) : rescue_with
      end
      hsh.merge! key => result
      hsh
    end
  end

protected
  ENABLE_PRESENT_DATASET_CACHE = false
  def prepare_present
    ActiveSupport::Notifications.instrument('gql.performance.graph.prepare_present') do
      # DEBT wrong. check for present_updated_at!!
      if ENABLE_PRESENT_DATASET_CACHE && scenario.update_statements_present.empty? && scenario.inputs_present.empty?
        present_graph.dataset ||= calculated_present_dataset
      else
        # If present_graph has user inputs then we have to take a fresh dataset.
        present_graph.dataset ||= dataset_clone
        UpdateInterface::Graph.new(self, present_graph).update_with(scenario.update_statements_present)
        scenario.inputs_present.each do |input, value|
          present.query(input, value)
        end
      end
    end
  end

  def prepare_future    
    ActiveSupport::Notifications.instrument('gql.performance.graph.prepare_future') do
      if Rails.env.test?
        future_graph.dataset ||= calculated_present_dataset
      else
        future_graph.dataset = dataset_clone
      end
      scenario.inputs_before.each do |input, value|
        future.query(input, value)
      end
      UpdateInterface::Graph.new(self, future_graph).update_with(scenario.update_statements)
      scenario.inputs_future.each do |input, value|
        future.query(input, value)
      end
    end
  end

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

end

end

