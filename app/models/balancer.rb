# Balances a group of inputs so that the sum of their values "balances" to a
# chosen number (typically 100).
#
# Uses Rational arithmetic internally to prevent floating-point precision from
# causing minor imperfections in balanced values.
#
# Terminology
#
#   user_values:
#     Inputs whose value has been set by a user is called a "user value". The
#     balancer is not permitted to change these inputs, except when repairing
#     drift (see INTENT_TOLERANCE).
#
#   subordinates:
#     Subordinates are all of the inputs in the group which are not user_values.
#     The balancer will alter the values of these inputs in order that the
#     group sums to the equilibrium.
#
#   equilibrium:
#     The value to which all the inputs should sum.
#
class Balancer
  # The intent tolerance: separates float drift from meaning. When Osmosis
  # reports that a group cannot be balanced, a group whose total deviates from
  # the equilibrium by no more than this is repaired by rescaling every member
  # value-proportionally; a larger deviation cannot be distinguished from a
  # typo and is refused.
  INTENT_TOLERANCE = 1e-6

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
    @equilibrium = Rational(equilibrium.to_d)
  end

  # The name of the share group being balanced.
  #
  # @return [String]
  #   The group name.
  #
  def group_name
    @inputs.any? ? @inputs.first.share_group.to_s.inspect : 'Unknown group'
  end

  # A human-readable version of the Balancer.
  #
  # @return [String]
  #   Shows the Balancer group and equilibrium.
  #
  def inspect
    "#<Balancer key=#{ group_name } equilibrium=#{ @equilibrium.to_f }>"
  end

  # Balances the inputs.
  #
  # Given one or more "user value" inputs, whose values have been set explicitly
  # by a user, all of the other "subordinate" inputs will have their values
  # changed.
  #
  # @param [Scenario] scenario
  #   A scenario with an end year and area code, used to get the input
  #   attributes.
  # @param [Hash<Symbol=>Integer>] user_values
  #   Inputs whose values have been set by the user, and should not be changed
  #   by the balancer.
  # @param [true, false] autobalance
  #   When false, every member is static: nothing may be moved to reach the
  #   equilibrium. A drift repair still applies — opting out of autobalancing
  #   is not opting into a rejection of data nobody mistyped.
  #
  # @return [Hash{Integer=>Numeric}]
  #   Returns a hash containing values for the inputs whose values were not
  #   provided by the user. When a drift repair has occurred the hash also
  #   contains corrected values for user value keys: the values being corrected
  #   are the user's own, and +user_values+ wins everywhere it is read, so
  #   the repair must land there to take effect.
  #
  def balance(scenario, user_values, autobalance: true)
    # Remove inputs which aren't members of the group being balanced.
    user_values = user_values.slice(*@inputs.map(&:key))

    # We don't need to do anything if there are no user_values. The group is at
    # the default values.
    return Hash.new if user_values.empty?

    members  = members_for(scenario, user_values, autobalance)
    balanced = Osmosis.balance(members, @equilibrium)

    # We return a hash containing the values for the subordinate inputs
    # converted to floats for convenient storage (Osmosis returns Rationals
    # which don't serialize so nicely into the +balanced_values+ column).
    balanced.each_with_object({}) do |(key, value), data|
      data[key] = value.to_f unless members[key][:static]
    end
  rescue Osmosis::NoVariablesError
    repair_drift(scenario, members) || raise(NoSubordinates.new(group_name, user_values))
  rescue Osmosis::CannotBalanceError
    repair_drift(scenario, members) || raise(CannotBalance.new(group_name, user_values))
  end

  # The canonical value of each member of the group: the user's value if one
  # is provided, otherwise the balanced value if one exists, otherwise the
  # dataset default. Every input in the group is a member — a disabled input
  # is not excluded (its slot keeps its default conversion, so a group summing
  # the remaining members to the equilibrium would break energy conservation);
  # it makes the group unresolvable instead (UnresolvableGroup).
  #
  # @return [Hash{String=>Numeric}]
  def member_values(scenario, user_values, balanced_values = {})
    member_caches(scenario).each_with_object({}) do |(key, cache), values|
      values[key] = user_values[key] || balanced_values[key] || cache[:default]
    end
  end

  # The members a value-proportional rescale of +values+ would push outside
  # their own min/max. Lets the validator explain why a repair was refused
  # instead of reporting a nonsensical "group sums to 100.0000000001".
  #
  # @return [Array<Hash>] one hash per breach: key, rescaled value, min, max.
  def repair_breaches(scenario, values)
    breaches_in(scenario, rescaled_values(values))
  end

  #######
  private
  #######

  # The cached attributes of every member of the group. A disabled member has
  # no min/max/default — its value cannot be known, so neither can the
  # group's balance — and makes the group unresolvable.
  def member_caches(scenario)
    @member_caches ||= @inputs.each_with_object({}) do |input, caches|
      cache = Input.cache(scenario).read(scenario, input)
      raise UnresolvableGroup.new(group_name, input.key, cache[:error]) if cache[:disabled]

      caches[input.key] = cache
    end
  end

  # The group's members as Osmosis elements. `static` means exactly one
  # thing: this value may not be moved — true for values the user provided,
  # and for every member when autobalancing is off.
  def members_for(scenario, user_values, autobalance)
    member_caches(scenario).each_with_object({}) do |(key, cache), members|
      value = user_values[key]

      members[key] = {
        min:    cache[:min],
        max:    cache[:max],
        value:  value || cache[:default],
        static: value.present? || !autobalance
      }
    end
  end

  # Repairs drift: when Osmosis has ruled the group unbalanceable and the
  # deviation from the equilibrium is within the intent tolerance, rescales
  # every member value-proportionally (× equilibrium/total). This preserves
  # the ratios between shares and leaves zero shares at exactly zero, which
  # Osmosis's own delta-proportional rule would drive negative.
  #
  # Returns nil — the caller re-raises — when the deviation is meaningful or
  # a rescaled value would breach a member's bounds.
  def repair_drift(scenario, members)
    values    = members.transform_values { |member| member[:value] }
    deviation = (rational_sum(values) - @equilibrium).abs

    return nil if deviation > INTENT_TOLERANCE

    rescaled = rescaled_values(values)
    return nil if breaches_in(scenario, rescaled).any?

    log_repair(scenario, deviation)
    rescaled.transform_values(&:to_f)
  end

  # The members of rescaled sitting outside their own min/max.
  def breaches_in(scenario, rescaled)
    caches = member_caches(scenario)

    rescaled.filter_map do |key, value|
      cache = caches[key]

      unless value.between?(cache[:min], cache[:max])
        { key: key, value: value.to_f, min: cache[:min], max: cache[:max] }
      end
    end
  end

  # The value-proportional rescale itself, exact in Rational.
  def rescaled_values(values)
    scale = @equilibrium / rational_sum(values)
    values.transform_values { |value| Osmosis.rational(value) * scale }
  end

  def rational_sum(values)
    values.values.sum(Rational(0)) { |value| Osmosis.rational(value) }
  end

  def log_repair(scenario, deviation)
    Rails.logger.info(
      "Repaired share-group drift: scenario=#{scenario.id} group=#{group_name} " \
      "deviation=#{deviation.to_f}"
    )
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

# An exception raised when a group contains a member whose value cannot be
# known (its input is disabled), making the group's balance unknowable.
class Balancer::UnresolvableGroup < Balancer::BalancerError
  attr_reader :input_key, :cache_error

  def initialize(group, input_key, cache_error)
    @group       = group
    @input_key   = input_key
    @cache_error = cache_error
  end

  def message
    "Cannot resolve group #{ @group }: the value of #{ @input_key } cannot " \
    "be determined (#{ @cache_error || 'input is disabled' })"
  end
end
