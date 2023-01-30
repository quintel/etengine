# frozen_string_literal: true

module ETEngine
  # Include in migrations which mass-update scenarios with new user values.
  module ScenarioMigration
    NoScenariosMigrated = Class.new(RuntimeError)

    REDUNDANT_AGGREGATE_KEYS = %w[
      industry_useful_demand_for_chemical_aggregated_industry
      industry_useful_demand_for_chemical_aggregated_industry_electricity_efficiency
      industry_useful_demand_for_chemical_aggregated_industry_useable_heat_efficiency
    ].freeze

    # Public: Yields all migrateable scenarios. If a scenario is changed while
    # yielded it will be saved.
    #
    # For example:
    #
    #   migrate_scenarios do |scenario|
    #     scenario.user_values[:new_input] = 1
    #   end
    #
    # raise_if_no_changes: -
    #   Raises an error if no scenarios were migrated. This is useful if you are
    #   expecting scenarios to be migrated and want to fail the migration if
    #   none were. This is particularly valuable when deploying automatically
    #   where this might not be noticed. (default: true)
    #
    # since: -
    #   By default, all read-only scenarios and writeable scenarios modified
    #   in the last month are migrated. `since` allows you to provide a custom
    #   cutoff date for migrating writable scenarios.
    #
    # Returns nothing.
    def migrate_scenarios(raise_if_no_changes: true, since: nil)
      collection = scenarios(since)
      total = collection.count
      changed = 0
      uv_changed = 0
      unrelated_changes = 0

      say("#{total} candidate scenarios for migration")

      collection.find_each.with_index do |scenario, index|
        begin
          yield(scenario)
        rescue Psych::DisallowedClass
          say("Skipping #{scenario.id} - invalid YAML", true)
        end

        if scenario.changed?
          uv_changed += 1 if scenario.user_values_changed?
          unless overlap(scenario.user_values_change)
            say(scenario.user_values_change)
            unrelated_changes += 1
          end

          scenario.save(validate: false, touch: false)
          changed += 1
        end

        if index.positive? && ((index + 1) % 1000).zero?
          say("#{index + 1}/#{total} (#{changed} migrated, #{uv_changed} changed user values of which #{unrelated_changes} unrelated)")
        end
      end

      say("#{total}/#{total} (#{changed} migrated)")

      # With continuous deployment, it might go unnoticed if no scenarios are
      # migrated. If the developer knows that zero migrated scenarios is an
      # error, they may
      raise NoScenariosMigrated if changed.zero? && raise_if_no_changes

      nil
    end

    def down
      ActiveRecord::IrreversibleMigration
    end

    private

    def scenarios(since)
      since.nil? ? Scenario.migratable : Scenario.migratable_since(since)
    end

    def overlap(uv_changes)
      REDUNDANT_AGGREGATE_KEYS.each do |key|
        return true if uv_changes[0].include?(key)
      end

      false
    end
  end
end
