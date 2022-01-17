# Included in scenario so that copies of the scenario are correctly
# configured, and don't pollute the original.
module Scenario::Copies
  private

  # Sets up clones and dups of the scenario.
  #
  # Typically used when we want to perform calculations using previous values
  # provided by a user, before their new values are applied (e.g. balancing).
  #
  # @param [Scenario] orig
  #   The original scenario that _self_ is cloned from.
  #
  def initialize_copy(orig)
    super
    @gql    = nil
    @inputs = nil
  end
end
