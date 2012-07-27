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
  #   A collection of inputs whose values should sum to `equilibrium`.
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
  # @param [Array<Input>] masters
  #   Inputs whose values have been set by the user, and should not be changed
  #   by the balancer.
  #
  # @return [Hash{Integer=>Numeric}]
  #   Returns a hash containing
  #
  def balance(scenario, masters)
    # Remove inputs which aren't known to the balancer.
    masters = masters.slice(*@inputs.map(&:key))

    # We don't need to do anything.
    return Hash.new if masters.empty?

    subordinates = subordinates_for(masters, scenario)

    if subordinates.empty?
      if already_balanced?(masters.values)
        # User has manually balanced the whole group.
        return Hash.new
      else
        raise NoSubordinates.new(group_name, masters)
      end
    end

    # Flex is the amount of "value" which needs to be adjusted for. For
    # example, if an input in a group is increased from 0 to 20, the sum of
    # all the inputs will come to 120. The flex will therefore be -20
    # indicating that the group needs to be reduced to 20 to compensate.
    flex = @equilibrium -
      (subordinates.map(&:start).sum + masters.values.sum).to_d

    iteration_inputs = subordinates.dup

    10.times do |iteration|
      next_inputs = []
      start_flex  = flex
      delta       = cumulative_delta(iteration_inputs)
      brute_force = false

      if start_flex.abs < (delta * 0.00001)
        # Assign flex first to the input with the most headroom.
        iteration_inputs.sort_by! do |input|
          -input.headroom(flex < 0 ? :down : :up)
        end

        brute_force = true
      end

      iteration_inputs.each do |input|
        if brute_force
          # Brute-force balancing: If the flex per input is too small (<0.001%
          # of the delta) we try to assign the full amount to an input.
          # This prevents running out of iterations as we divide into ever
          # smaller flexes.
          flex_per_input = start_flex
        else
          # Fair, round-robin balancing: The amount of flex given to each
          # input is calculated for each input separately, since a previous
          # iteration may have used all all of the flex due to rounding.
          flex_per_input = start_flex * (input.delta / delta)
        end

        prev_value = input.value
        new_value  = input.set_value(prev_value + flex_per_input)

        flex       -= new_value - prev_value
        start_flex -= new_value - prev_value if brute_force

        # Finally, if this input can still be changed further, it may be used
        # again in the next iteration.
        if input.can_change?(flex < 0 ? :down : :up)
          next_inputs.push(input)
        end
      end # iteration_inputs.each ...

      # These inputs will be used the next time around...
      iteration_inputs = next_inputs

      # If the flex is all used up, or wasn't changed, don't waste time with
      # more iterations.
      break if flex.zero? or flex == start_flex
    end # 20.times do ...

    raise CannotBalance.new(group_name, masters) unless flex.zero?

    subordinates.each_with_object(Hash.new) do |input, memo|
      memo[ input.key ] = input.value
    end
  end

  #######
  private
  #######

  # Returns the inputs whose values can be changed to balance the group.
  #
  # @param [Array<Input>] masters
  #   The "master" inputs, whose values have been changed by the user, and may
  #   not be used for balancing.
  # @param [Scenario] scenario
  #   Scenario instance used for fetching start values, minima, and maxima.
  #
  # @return [Array<Input>]
  #
  def subordinates_for(masters, scenario)
    keys = masters.keys

    @inputs.
      reject { |input| keys.include?(input.key) }.
      map    { |input| BalancedInput.new(input, scenario) }
  end

  # Calculates the delta (difference between the maximum and minimum values)
  # of all of the given BalancedInputs.
  #
  # @param [Array<BalancedInput>]
  #   The inputs whose delta will be calculated.
  #
  # @return [Float]
  #
  def cumulative_delta(inputs)
    inputs.map(&:delta).sum
  end

  # Determines if the group is balanced by the given master values.
  #
  # Permits a tiny variation from the equilibrium to account for floating
  # point precision in math outside the balancer (e.g. in JavaScript).
  #
  # @param [Array<Numeric>] values
  #   The master values.
  #
  # @return [true, false]
  #
  def already_balanced?(values)
    values.sum.between?(@equilibrium - 0.1, @equilibrium + 0.1)
  end

end # Balancer

# Wraps around Input to provide some useful helper methods used when balancing
# share groups.
class Balancer::BalancedInput

  # @return [Numeric]
  #   Returns the current value of the Input.
  attr_reader :value

  # Creates a new BalancedInput.
  #
  # @param [Input] input
  #   The input to be wrapped by the BalancedInput.
  # @param [Scenario] scenario
  #   Used for fetching dynamic start, minimum, and maximum values.
  # @param [Numeric] value
  #   An optional starting value for the Input. If no value is provided, it
  #   will default to the inputs start value.
  #
  # @raise [BalanceError]
  #   Raises a balance error when no starting value is given, and the input
  #   could not determine it's own start value.
  #
  def initialize(input, scenario)
    @input    = input
    @scenario = scenario
    @cache    = nil

    @value    = start

    if @value.nil?
      raise BalanceError, "No start value for input #{ @input.key.inspect }"
    end
  end

  # Returns if the input may be altered by the balancer.
  #
  # @param [Symbol] direction
  #   The direction in which you want to change the input. :up or :down.
  #
  # @return [true, false]
  #   Returns if the Input may be altered by the balancer.
  #
  def can_change?(direction)
    not disabled? and not headroom(direction).zero?
  end

  # Returns how much headroom is available in a given direction.
  #
  # @param [Symbol] direction
  #   The direction in which you want to change the input. :up or :down.
  #
  # @return [BigDecimal]
  #   Returns the available headroom.
  #
  # @example Moving the input up, current value of 48, max value of 50.
  #   input.headroom(:up) # => 2.0
  #
  # @example Moving the slider down, current value of 2, min value of -100.
  #   input.headroom(:down) # => 102.0
  #
  def headroom(direction)
    ((direction == :up ? maximum : minimum) - @value).abs
  end

  # @return [String]
  #   Returns the unique key for the input.
  #
  def key
    @input.key
  end

  # Sets a new value for the input.
  #
  # Currently does not account for the `step` attribute..
  #
  # @param [Numeric]
  #   The value to be set.
  #
  # @return [Numeric]
  #   Returns the actual value which was set. This may differ from the value
  #   you tried to set if the value you tried to set falls outside the
  #   permitted range.
  #
  def set_value(value)
    if value > maximum
      @value = maximum
    elsif value < minimum
      @value = minimum
    else
      @value = value.to_d
    end
  end

  # @return [Float]
  #   Returns the starting value for the input.
  #
  def start
    input_value(:start, minimum)
  end

  # @return [Float]
  #   The minimum value to which the input may be set.
  #
  def minimum
    input_value(:minimum)
  end

  # @return [Float]
  #   The maximum value to which the input may be set.
  #
  def maximum
    input_value(:maximum)
  end

  # @return [Float]
  #   Returns the difference between the input minimum and maximum.
  #
  def delta
    @delta ||= maximum - minimum
  end

  # @return [true, false]
  #   Returns if the input is disabled in the current area.
  #
  def disabled?
    input_value(:disabled)
  end

  # @return [String]
  #   A human-readable version of the input for debugging.
  #
  def inspect
    "#<Balancer::BalancedInput " \
      "id=#{ @input.lookup_id.inspect } " \
      "key=#{ @input.key.inspect } " \
      "value=#{ value.to_s.inspect }>"
  end

  #######
  private
  #######

  # Returns an input start, minimum, or maximum value.
  #
  # @param [Symbol] name
  #   One of :start, :min, or :max.
  # @param [Numeric] fallback
  #   A fallback value in case no value could be computed.
  #
  # @return [BigDecimal]
  #
  def input_value(name, fallback = nil)
    @cache ||= Input.cache.read(@scenario, @input)

    value = case name
      when :start    then @cache[:default]
      when :minimum  then @cache[:min]
      when :maximum  then @cache[:max]
      when :disabled then @cache[:disabled]
      else
        raise BalancerError, "Unknown attribute: #{ name }"
    end

    # Values may be wrapped in an array.
    # TODO Why? This should not happen.
    value = value.first if value.is_a?(Array)

    if value.present?
      value.respond_to?(:to_d) ? value.to_d : value
    else
      fallback
    end
  end
end # Balancer::BalancedInput

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
