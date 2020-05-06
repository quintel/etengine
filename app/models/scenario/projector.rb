# frozen_string_literal: true

class Scenario
  # Create a new scenario with settings from two scenarios.
  class Projector
    attr_reader :onto, :from, :sliders, :result
    def initialize(from, onto, sliders)
      @from = from
      @onto = onto
      @sliders = sliders
    end

    # This implementation is really naive. We still have to autobalance
    # sharegroups. ScenarioUpdater seems a bit smarter about this but I'm
    # having trouble deciphering it.
    # There would be two ways to acomplish this:
    # - Leverage ScenarioUpdater
    # - Write a service to balance a sharegroup

    def call
      attributes = onto.attributes.except("id", "user_values")
      from_user_values =
        from.user_values
          .select { |key,value| @sliders.include? key }

      attributes[:user_values] = onto.user_values.merge(from_user_values)

      Scenario.create(attributes)
    end

    def as_json(options)
      { id: call.id }
    end
  end
end
