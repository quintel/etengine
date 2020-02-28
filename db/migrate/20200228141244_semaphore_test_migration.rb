# A migration intended to track down failing migrations when running a deploy
# from Semaphore.
class SemaphoreTestMigration < ActiveRecord::Migration[5.2]
  def up
    update_scenarios do |scenario|
      scenario.user_values['heat_storage_enabled'] = 1
    end
  end

  def down
  end

  def update_scenarios
    total = scenarios.count
    changed = 0

    say "Checking and migrating #{total} scenarios"
    say "RAILS_ENV=#{Rails.env.inspect}"
    say ""

    scenarios.find_each.with_index do |scenario, index|
      if Atlas::Dataset.exists?(scenario.area_code)
        before = scenario.user_values.dup

        yield(scenario)

        say "Scenario = #{scenario.id}"
        say "before = #{before.inspect}, after = #{scenario.user_values.inspect}"
        say "changed? = #{scenario.changed?.inspect}"
        say ""

        if scenario.changed?
          scenario.save(validate: false, touch: false)
          changed += 1
        end
      end

      if index.positive? && ((index + 1) % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  def scenarios
    Scenario.where(id: [1276116, 1276118])
  end
end
