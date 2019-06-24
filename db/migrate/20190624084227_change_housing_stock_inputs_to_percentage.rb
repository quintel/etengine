# frozen_string_literal: true

# Updates scenarios to change number_of_ households inputs to be instead
# describe the share of each household type.
class ChangeHousingStockInputsToPercentage < ActiveRecord::Migration[5.1]
  INPUTS = %w[
    apartments
    corner_houses
    detached_houses
    semi_detached_houses
    terraced_houses
  ].freeze

  OLD_KEY = 'households_number_of_%<input_key>s'
  NEW_KEY = 'households_%<input_key>s_share'

  def up
    # Iterates through each scenario which may need to be migrated. Each
    # scenario is yielded to the block.
    update_scenarios do |scenario|
      # Skip this scenario unless it has at least one "number_of_..." input set.
      next unless scenario_has_inputs?(scenario, OLD_KEY)

      # Calculate this before updating the input names, otherwise it will always
      # return the default for the dataset.
      residences = number_of_residences(scenario)

      # Iterate through each "number_of_..." input. This will rename the input
      # from the old format (number_of_) to the new (_share) and transform the
      # value using the block (divide by number of residences, and convert to a
      # percentage).
      update_inputs(scenario, OLD_KEY, NEW_KEY) do |value|
        value / residences * 100
      end

      scenario.user_values['households_number_of_residences'] = residences
    end
  end

  def down
    update_scenarios do |scenario|
      if scenario_has_inputs?(scenario, NEW_KEY)
        # The scenario has one or more of the _share inputs, so we set the
        # number of each type of household. Any which are not set will use the
        # dataset default.
        residences = number_of_residences(scenario)

        update_inputs(scenario, NEW_KEY, OLD_KEY) do |value|
          value / 100 * residences
        end

      elsif scenario.user_values.key?('households_number_of_residences')
        # The scenario has a number of residences, but no shares for each type.
        # We have to set the number of each to respect the number of residences
        # set by the creator.
        residences = scenario.user_values['households_number_of_residences']
        dataset = Atlas::Dataset.find(scenario.area_code)

        INPUTS.each do |key|
          share =
            dataset.send("number_of_#{key}") / dataset.number_of_residences

          scenario.user_values[format(OLD_KEY, input_key: key)] =
            residences * share
        end
      end

      scenario.user_values.delete('households_number_of_residences')
    end
  end

  private

  # Iternates through and yields each scenario which might require migrating.
  #
  # Yields each scenario to the block, and saved the record if any changes are
  # made.
  def update_scenarios
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    scenarios.find_each.with_index do |scenario, index|
      if Atlas::Dataset.exists?(scenario.area_code)
        yield(scenario)

        if scenario.changed?
          scenario.save(validate: false, touch: false)
          changed += 1
        end
      end

      if index.positive? && (index % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  # Detects if the scenario has any inputs matching the the template.
  def scenario_has_inputs?(scenario, template)
    INPUTS.any? do |key|
      scenario.user_values.key?(format(template, input_key: key))
    end
  end

  # Given a scenario, updates all of the INPUTS matching the from_template
  # string, renaming them to the to_template string.
  def update_inputs(scenario, from_template, to_template, &action)
    INPUTS.each do |input_key|
      update_input(
        scenario,
        format(from_template, input_key: input_key),
        format(to_template, input_key: input_key),
        &action
      )
    end
  end

  # Changes an input in a `scenario` from the `from` key to the `to` key, which
  # is the percentage of the housing type compared to the total number of
  # residences.
  #
  # If the `from` key is not present, returns a falsey value.
  def update_input(scenario, from, to)
    return false unless scenario.user_values.key?(from)

    scenario.user_values[to] = yield(scenario.user_values.delete(from))

    true
  end

  def number_of_residences(scenario)
    if scenario.user_values.key?('households_number_of_residences')
      # Rolling back.
      return scenario.user_values['households_number_of_residences']
    end

    # Migrating up.
    INPUTS.sum do |key|
      scenario.user_values["households_number_of_#{key}"] ||
        Atlas::Dataset.find(scenario.area_code).send("number_of_#{key}")
    end
  end

  # All protected scenarios, and any unprotected scenarios since Jan 1st 2019
  # will be updated.
  def scenarios
    Scenario.migratable_since(Date.new(2019, 1, 1))
  end
end
