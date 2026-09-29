# frozen_string_literal: true

module ETEngine
  # Include in migrations which mass-update scenarios with new user values.
  module ScenarioMigration
    NoScenariosMigrated = Class.new(RuntimeError)

    NO_CHANGES_MESSAGE =
      'No scenarios were changed. If this database holds no scenarios the migration ' \
      'applies to, re-run with SKIP_SCENARIO_CHECK=1 to record it as applied.'

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
    #   where this might not be noticed. Never raises while migrating the test
    #   database. (default: true)
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

      say("#{total} candidate scenarios for migration")

      collection.find_each.with_index do |scenario, index|
        begin
          yield(scenario)
        rescue Psych::DisallowedClass
          say("Skipping #{scenario.id} - invalid YAML", true)
        end

        if scenario.changed?
          scenario.save(validate: false, touch: false)
          changed += 1
        end

        if index.positive? && ((index + 1) % 1000).zero?
          say("#{index + 1}/#{total} (#{changed} migrated)")
        end
      end

      say("#{total}/#{total} (#{changed} migrated)")

      # With continuous deployment, it might go unnoticed if no scenarios are
      # migrated.
      if raise_if_no_changes && changed.zero? && !skip_no_changes_check?
        raise NoScenariosMigrated, NO_CHANGES_MESSAGE
      end

      nil
    end

    def down
      ActiveRecord::IrreversibleMigration
    end

    private

    # Internal: Prints a heading followed by the number of scenarios per area,
    # for example those a migration skipped. Prints nothing when there are none.
    #
    # heading - The line printed above the tally.
    # areas   - A Hash of area codes to their number of scenarios.
    #
    # For example:
    #
    #   skipped = Hash.new(0)
    #   skipped[scenario.area_code] += 1
    #   print_report('Skipped scenarios:', skipped)
    #
    # Returns nothing.
    def print_report(heading, areas)
      return if areas.empty?

      say(heading)

      areas.sort.each do |area_code, scenarios|
        say("#{scenarios} #{'scenario'.pluralize(scenarios)} from #{area_code}", true)
      end
    end

    def skip_no_changes_check?
      test_database? || ENV['SKIP_SCENARIO_CHECK'].present?
    end

    # True while migrating the test database.
    def test_database?
      ActiveRecord::Base.connection_db_config.env_name == 'test'
    end

    def scenarios(since)
      since.nil? ? Scenario.migratable : Scenario.migratable_since(since)
    end
  end
end
