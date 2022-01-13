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

    # Public: A set of inputs which are set in the scenario which are disabled due to the presence
    # of one or more conflicting exclusive inputs.
    #
    # input - The input to check for exclusivity conflicts.
    #
    # Returns a Set[Input].
    def disabled_by_exclusivity?(input)
      exclusivity_disabled.include?(input.key.to_s)
    end

    private

    # Internal: A set containing all the inputs which are disabled by exclusivity conflicts.
    def exclusivity_disabled
      @exclusivity_disabled ||= Set.new(all_inputs.map(&:disables).flatten)
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
      return @enabled_inputs if @enabled_inputs

      inputs = all_inputs.dup

      exclusivity_disabled.each do |disabled|
        inputs.delete(Input.get(disabled))
      end

      @inputs = inputs.sort_by { |input| [-input.priority, input.key] }
    end

    # Internal: All inputs active in the scenario, including those which may later be considered
    # disabled.
    def all_inputs
      @all_inputs ||= combined_values.map { |key, _| Input.get(key) }.compact
    end

    # Internal: All of the inputs values to be set; includes the values
    # specified by the user, and any values from the balancer.
    #
    # Returns an hash.
    def combined_values
      @combined_values ||= @scenario.balanced_values.merge(@scenario.user_values)
    end
  end
end
