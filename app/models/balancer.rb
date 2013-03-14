# Balances a group of inputs so that the sum of their values "balances" to a
# chosen number (typically 100).
#
# Uses BigDecimal internally to prevent floating-point precision from causing
# minor imperfections in balanced values.
#
# Terminology
#
#   masters:
#     Inputs whose value has been set by a user is called a "master". The
#     balancer is not permitted to change these inputs.
#
#   subordinates:
#     Subordinates are all of the inputs in the group which are not masters.
#     The balancer will alter the values of these inputs in order that the
#     group sums to the equilibrium.
#
#   equilibrium:
#     The value to which all the inputs should sum.
#
class Balancer
  # Creates a new Balancer instance.
  #
  # @params [Array<Input>] inputs
  #   A collection of inputs whose values should sum to +equilibrium+.
  # @param [Numeric] equilibrium
  #   The value to which the inputs should sum.
  #
  # @example
  #   Balancer.new(inputs).balance(scenario, params)
  #   # => { 1 => 42.0, ... }
  #
  def initialize(inputs, equilibrium = 100.0)
    @inputs      = inputs
    @equilibrium = equilibrium.to_d
  end

  # The name of the share group being balanced.
  #
  # @return [String]
  #   The group name.
  #
  def group_name
    @inputs.any? ? @inputs.first.share_group.inspect : 'Unknown group'
  end

  # A human-readable version of the Balancer.
  #
  # @return [String]
  #   Shows the Balancer group and equilibrium.
  #
  def inspect
    "#<Balancer key=#{ group_name } equilibrium=#{ @equilibrium }>"
  end

  # Balances the inputs.
  #
  # Given one or more "master" inputs, whose values have been set explicitly
  # by a user, all of the other "subordinate" inputs will have their values
  # changed.
  #
  # @param [Scenario] scenario
  #   A scenario with an end year and area code, used to get the input
  #   attributes.
  # @param [Hash<Symbol=>Integer>] masters
  #   Inputs whose values have been set by the user, and should not be changed
  #   by the balancer.
  #
  # @return [Hash{Integer=>Numeric}]
  #   Returns a hash containing values for the inputs whose values were not
  #   provided by the user.
  #
  def balance(scenario, user_values)
    # Remove inputs which aren't members of the group being balanced.
    user_values = user_values.slice(*@inputs.map(&:key))

    # We don't need to do anything if there are no masters. The group is at
    # the default values.
    return Hash.new if user_values.empty?

    for_osmosis = @inputs.each_with_object({}) do |input, data|
      data[input.key] = osmosis_hash(scenario, input, user_values[input.key])
    end

    balanced = Osmosis.balance(for_osmosis, @equilibrium)

    # We return a hash containing the values for the subordinate inputs
    # converted to floats for convenient storage (Osmosis returns Rationals
    # which don't serialize so nicely into the +balanced_values+ column).
    balanced.each_with_object({}) do |(key, value), data|
      data[key] = value.to_f unless user_values.key?(key)
    end
  rescue Osmosis::NoVariablesError
    raise NoSubordinates.new(group_name, user_values)
  rescue Osmosis::CannotBalanceError
    raise CannotBalance.new(group_name, user_values)
  end

  #######
  private
  #######

  # Given an input, creates a hash which can be provided to Osmosis as one of
  # the values in the group.
  #
  # @param [Input] input
  #   The input to be converted to an Osmosis-compatible hash.
  # @param [Numeric, false] value
  #   Does this have a user-provided value for the input? If so, what is it?
  #
  # @return [Hash]
  #   Returns a Hash, ready for Osmosis.
  def osmosis_hash(scenario, input, value)
    cache = Input.cache.read(scenario, input)

    { min:    cache[:min],
      max:    cache[:max],
      value:  value || cache[:default],
      static: value.present? || cache[:disabled] }
  end
end # Balancer

# A generic error class for Balancer errors.
class Balancer::BalancerError < RuntimeError
end

# An exception class raised when the balancer could not reach an equilibrium.
class Balancer::CannotBalance < Balancer::BalancerError
  def initialize(group, values)
    @group  = group
    @values = values
  end

  def message
    "Could not balance group #{ @group } with values #{ @values.inspect }"
  end
end

# An exception raised when trying to balance a group, but there were no other
# inputs available to perform the balancing.
class Balancer::NoSubordinates < Balancer::CannotBalance
  def message
    "There were no subordinates to balance group #{ @group } " \
    "with values #{ @values.inspect }"
  end
end
