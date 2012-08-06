# Included in scenario so that copies of the scenario are correctly
# configured, and don't pollute the original.
module Scenario::Copies

  #######
  private
  #######

  # Sets up a duplicate of the scenario.
  #
  # @param [Scenario] other
  #   The dup'ed scenario.
  #
  # @see Scenario#initialize_copy
  #
  def initialze_dup(other)
    initialize_copy(other)
    super
  end

  # Sets up a clone of the scenario.
  #
  # @param [Scenario] other
  #   The cloned scenario.
  #
  # @see Scenario#initialize_copy
  #
  def initialize_clone(other)
    initialize_copy(other)
    super
  end

  # Sets up clones and dups of the scenario.
  #
  # Typically used when we want to perform calculations using previous values
  # provided by a user, before their new values are applied (e.g. balancing).
  #
  # @param [Scenario] other
  #   The cloned scenario.
  #
  def initialize_copy(other)
    other.instance_variable_set(:@gql,            nil)
    other.instance_variable_set(:@inputs_before,  nil)
    other.instance_variable_set(:@inputs_present, nil)
    other.instance_variable_set(:@inputs_future,  nil)
  end

end # Scenario::Copies
