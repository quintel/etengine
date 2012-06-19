# Wrapper for (user-) variables of a request that are accessible to all models.
#
# == Scenario vs Setting
#
# A big difference between Setting and Scenario is, that Scenario influences the GQL.
# E.g. in scenario we set end_year, etc.
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
  end

  def scenario
    session[:scenario] ||= Scenario.default
  end

  # ----- Resetting -----------------------------------------------------------


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
