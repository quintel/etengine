##
# Wrapper for (user-) variables of a request that are accessible to all models.
#
# == Current.scenario
#
# At any point if you want to reset the scenario:
#
#   Current.reset_to_default_scenario!
#   # which is the same as:
#   Current.scenario = Scenario.default
#
# == Scenario vs Setting
#
# A big difference between Setting and Scenario is, that Scenario influences the GQL.
# E.g. in scenario we set end_year, etc.
#
#
# == Implementation details
#
# Current is a Singleton. Because it is used often throughout the model (and
# because of legacy-reasons), Current is also the shortcut for Current.instance.
# This is implemented by generating class methods calling the singleton methods.
#
# I chose not to use the singleton module "include Singleton" because I want to
# actually be able to reset the Current by setting the @@instance to nil. Singleton
# module won't let you do this.
#
# The three objects to keep track of are: scenario, graph and gql. Check how 
# ApiRequest#response sets them up. It would be nice to have this initialization as
# straightforward as possible.
# 
class Current
  attr_accessor :graph_id

  def session
    @session ||= {}
  end

  def session=(session)
    @session = session
  end

  def scenario=(scenario)
    session[:scenario] = scenario
    scenario.load!
  end

  def scenario
    session[:scenario] ||= Scenario.default
  end

  # ----- Obsolete after switch to ETsource -----------------------------------

  # TODO refactor or make a bit more clear&transparent
  def graph
    unless @graph
      region_or_country = scenario.region_or_country
      @graph = self.user_graph

      raise "No graph for: #{region_or_country}" unless @graph
      raise "No Area data for: #{region_or_country}" unless Area.find_by_country(region_or_country)
    end
    @graph
  end

  ##
  # Manually set the Graph that is active for the GQl
  #
  # @param [Graph] graph
  #
  def graph=(graph)
    @graph = graph
  end

  # TODO renmae user_graph to graph... but we have def graph already :(
  def user_graph
    if self.graph_id
      Graph.find(self.graph_id)
    else
      region_or_country = scenario.region_or_country
      Graph.latest_from_country(region_or_country)
    end
  end

  # ----- /Obsolete after switch to ETsource -----------------------------------

  ##
  # is the GQL calculated? If true, prevent the programmers
  # to add further update statements ({Scenario#add_update_statements}).
  # Because they won't affect the system anymore.
  #
  # @return [Boolean]
  #
  def gql_calculated?
    # We have to access the gql with @gql, because accessing it with self.gql
    # would initialize it. If gql is not initialized it is also not calculated.
    @gql.andand.calculated? == true
  end

  # Initializes the GQL and makes it accessible through Current.gql
  #
  def gql
    # ---- Old approach of accessing gql ---------------
    # @gql ||= graph.andand.gql

    # ---- New approach of accessing gql ---------------
    # Passing a scenario as an argument to the gql will load the graph and dataset from ETsource.
    @gql ||= Gql::Gql.new(Current.scenario)
    # At this point gql is not "prepared" see {Gql::Gql#prepare}. 
    # We could force it here to always prepare, but that would slow things down
    # when nothing has changed in a scenario. Uncommenting this would decrease performance
    # but could get rid of bugs introduced by forgetting to prepare in some cases when we 
    # access the graph through the gql (e.g. Current.gql.present_graph.converters.map(&:demand)).
    # @gql.prepare
    @gql
  end

  def gql=(gql)
    @gql = gql
  end

  # ----- Resetting -----------------------------------------------------------

  # Resets to all default values. Will also reset country and year!
  #
  # Do not use this method to reset slider values!
  #
  # @untested 2010-12-27 seb
  #
  def reset_to_default!
    reset_to_default_scenario!
  end

  # Set to default scenario. Also overwrites year and country values!
  #
  # Do not use this method to reset slider values!
  #
  # @untested 2010-12-27 seb
  #
  def reset_to_default_scenario!
    scenario = Scenario.default
  end

  # Resets the scenarios from user values. But not what country, year we're in.
  #
  # @untested 2010-12-27 seb
  #
  def reset_scenario!
    scenario.reset
  end

  def reset_user_session!
    self.reset_to_default!
  end

  def reset_gql
    self.scenario.reset!
    self.gql = nil
    self.graph_id = nil
    @graph = nil
  end

  ##
  # Singleton instance
  #
  def self.instance
    @instance ||= Current.new
  end

  ##
  # Run after every request. Make sure, that other users don't use
  # the current settings.
  #
  def self.teardown_after_request!
    @instance = nil
  end

  ##
  # Forward methods to the (singleton)-instance methods.
  # So that we can type Current.foo instead of Current.instance.foo
  #
  class << self
    def method_missing(name, *args)
      self.instance.send(name, *args)
    end
  end
end
