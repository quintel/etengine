# frozen_string_literal: true

class Scenario < ApplicationRecord
  # Helper class which provides a list of inputs to be executed for a scenario.
  class Inputs
    def initialize(scenario)
      @scenario = scenario
    end

    # Public: Returns a hash containing the "before" inputs and their values.
    #
    # Returns a Hash[Input => Object].
    def before
      @before ||= Input.before_inputs.each_with_object({}) do |input, data|
        data[input] = @scenario.end_year
      end
    end

    # Public: Returns a hash containing the inputs that are to be executed on the present graph and
    # their values.
    #
    # Returns a Hash[Input => Object].
    def present
      @present ||= inputs_for_graph(:present)
    end

    # Public: Returns a hash containing the inputs that are to be executed on the present graph and
    # their values.
    #
    # Returns a Hash[Input => Object].
    def future
      @future ||= inputs_for_graph(:future)
    end

    # Public: Returns if the input should be disabled due to constraints or flags set on the
    # scenario.
    #
    # input - The input to check.
    #
    # Returns a boolean.
    def disabled?(input)
      disabled_by_exclusivity?(input) || disabled_by_curve?(input) || disabled_by_coupling?(input)
    end

    private

    # Internal: A set containing all the inputs which are disabled by exclusivity conflicts.
    def exclusivity_disabled
      @exclusivity_disabled ||= Set.new(
        all
          .select { |input| input.disabled_by.any? { |key| combined_values.key?(key) } }
          .map(&:key)
      )
    end

    # Internal: A hash of inputs and the values to be set on the named graph.
    #
    # name - The "period" of the graph for which you want values; :future or :present.
    #
    # Returns a Hash[Input => Object].
    def inputs_for_graph(period)
      enabled_inputs
        .select { |input| input.public_send(:"updates_#{period}?") }
        .each_with_object({}) { |input, hash| hash[input] = combined_values[input.key] }
    end

    # Internal: The inputs for which the user - or balancer - has specified a value.
    #
    # If any inputs contain a value which result in another input being disabled, the disabled
    # inputs are omitted from the list.
    #
    # Returns an array of inputs, in order of their execution priority.
    def enabled_inputs
      @enabled_inputs ||= all
        .reject { |input| disabled_by_exclusivity?(input) || disabled_by_curve?(input) || disabled_by_coupling?(input) }
        .sort_by { |input| [-input.priority, input.key] }

      @enabled_inputs
    end

    # Internal: All inputs active in the scenario, including those which may later be considered
    # disabled.
    def all
      @all ||= combined_values.map { |key, _| Input.get(key) }.compact
    end

    # Internal: All of the inputs values to be set; includes the values
    # specified by the user, and any values from the balancer.
    #
    # Returns an hash.
    def combined_values
      @combined_values ||= @scenario.balanced_values.merge(@scenario.user_values)
    end

    # Internal: A set of inputs which are set in the scenario which are disabled due to the presence
    # of one or more conflicting exclusive inputs.
    #
    # input - The input to check for exclusivity conflicts.
    #
    # Returns a Set[Input].
    def disabled_by_exclusivity?(input)
      input.disabled_by.any? { |key| combined_values.key?(key) }
    end

    # Internal: Returns if the input is disabled by a custom user curve which has been set.
    def disabled_by_curve?(input)
      inputs_disabled_by_curves.include?(input.key)
    end

    # Interal: Returns if the input is disabled by an active coupling
    # An input can be disabled by a coupling when it's active, or when
    # the input has a coupling group, it will be disabled when the coupling
    # is inactive
    def disabled_by_coupling?(input)
      (
        input.disabled_by_couplings.present? &&
        input.disabled_by_couplings.all? { |key| @scenario.active_couplings.include?(key) }
      ) || (
        input.coupling_groups.present? &&
        input.coupling_groups.any? { |key| @scenario.active_couplings.exclude?(key) }
      )
    end

    def inputs_disabled_by_curves
      @inputs_disabled_by_curves ||= Set.new(
        @scenario.attachments
          .select(&:curve?)
          .select(&:loadable_curve?)
          .flat_map { |attachment| attachment.curve_config.internal_disabled_inputs }
      )
    end
  end
end
