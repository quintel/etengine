module Gql
# GQL (Graph Query Language) is to a Graph/Qernel what SQL is to a database.
#
# It is responsible to update the future graph with user values/assumptions
# and to query the present and future graph using GQL Queries (Gquery).
#
class Gql
  extend ActiveModel::Naming
  include Instrumentable


  ENABLE_QUERY_CACHE_FOR_FUTURE = true

  attr_accessor :present_graph, :future_graph, :dataset, :scenario, :calculated
  attr_reader :graph_model, :sandbox_mode

  # Initialize a Gql instance by passing a (api) scenario
  #
  #
  #   
  # @example Initialize with scenario
  #   gql = ApiScenario.default.gql(prepare: true)
  #   gql.query(...)
  #
  # @example Initialize manually:
  #   gql = Gql::Gql.new(ApiScenario.default)
  #   gql.prepare
  #   gql.query(...)
  #
  # @example Initialize with scenario and individually prepare the gql
  #   gql = ApiScenario.default.gql(prepare: false)
  #   gql.init_datasets
  #   gql.update_present
  #   gql.update_future
  #   gql.present_graph.calculate   
  #   gql.future_graph.calculate
  #   gql.calculated = true
  #   gql.query(...)
  #
  #
  # @param [Graph] graph_model
  # @param [Dataset,String] dataset Dataset or String for country
  #
  def initialize(scenario)
    if scenario.is_a?(Scenario)
      @scenario = scenario
      loader    = Etsource::Loader.instance
      @present_graph = loader.graph.tap{|g| g.year = @scenario.start_year}
      @future_graph  = loader.graph.tap{|g| g.year = @scenario.end_year}
      @dataset = loader.dataset(@scenario.area_code)
    end
  end

  # @param [:console, :sandbox] mode The GQL sandbox mode.
  def sandbox_mode=(mode)
    @sandbox_mode = mode
    @present = QueryInterface.new(self, present_graph, sandbox_mode: mode)
    @future  = QueryInterface.new(self, future_graph,  sandbox_mode: mode)
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
    instrument("gql.performance.dataset_clone") do
      Marshal.load(Marshal.dump(@dataset))
    end
  end

  # @return [QueryInterface]
  #
  def present
    # Disable Caching of Gqueries until a smart solution has been found
    # @present ||= QueryInterface.new(self, present_graph, :cache_prefix => "#{scenario.id}-present-#{scenario.present_updated_at}")
    @present ||= QueryInterface.new(self, present_graph)
  end

  # @return [QueryInterface]
  #
  def future
    # Disable Caching of Gqueries until a smart solution has been found
    # @future ||= if ENABLE_QUERY_CACHE_FOR_FUTURE && !scenario.test_scenario?
    #   QueryInterface.new(self, future_graph, :cache_prefix => "#{scenario.id}-#{scenario.updated_at}")
    # else
    @future ||= QueryInterface.new(self, future_graph)
  end

  # Are the graphs calculated? If true, prevent the programmers
  # to add further update statements ({Scenario#add_update_statements}).
  # Because they won't affect the system anymore.
  #
  # When calculated changes through update statements
  # should no longer be allowed, as they won't have an impact on the
  # calculation (even though updating prices would work).
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
  # @example Query with a Gquery instance
  #   gql.query(Gquery.first)
  # @example Query with a string
  #   gql.query("SUM(1.0, 2.0)")         # => [[2010, 3.0],[2040,3.0]]
  # @example Query with a string that includes a query modifier (present/future)
  #   gql.query("present:SUM(1.0, 2.0)") # => 3.0
  # @example Query with a proc/lambda
  #   gql.query(-> { SUM(1,2) })         # => 3
  #
  # @param query [String, Gquery, Proc] A query object
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
    
    instrument("gql.query.#{key}.#{strategy}") do
      if strategy.nil?
        query_standard(query)
      elsif Gquery::GQL_MODIFIERS.include?(strategy.strip)
        send("query_#{strategy}", query)
      end
    end
  rescue Exception => e
    raise "Error running #{key}: #{e.inspect}"
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
    log = 'gql.performance.'
    instrument(log+'init_datasets')    { init_datasets }
    instrument(log+'update_graphs')    { update_graphs }
    instrument(log+'calculate_graphs') { calculate_graphs }
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

  def init_datasets
    present_graph.dataset ||= dataset_clone
    future_graph.dataset = dataset_clone
  end

  def update_graphs
    # 2011-08-15: the present has to be prepared first. otherwise
    # updating the future won't work (we need the present values)
    update_present
    update_future
  end

  def calculate_graphs
    present_graph.calculate
    future_graph.calculate
    @calculated = true
  end

  def update_present
    instrument('gql.performance.present.update_present') do
      UpdateInterface::Graph.new(self, present_graph).update_with(scenario.update_statements_present)
      scenario.inputs_present.each { |input, value| present.query(input, value) }
    end
  end

  def update_future
    instrument('gql.performance.future.update_future') do
      scenario.inputs_before.each { |input, value| future.query(input, value) }
      UpdateInterface::Graph.new(self, future_graph).update_with(scenario.update_statements)
      scenario.inputs_future.each { |input, value| future.query(input, value) }
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

