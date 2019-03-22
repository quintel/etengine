class ChangeIndustryChpUltraSupercriticalCoalCapacity < ActiveRecord::Migration[5.1]
  INPUT_KEY = 'number_of_industry_chp_ultra_supercritical_coal'.freeze
  INPUT_MULTIPLIER = 17.3611111111111 / 600.0

  def change
    reversible do |dir|
      dir.up do
        update_scenarios(INPUT_MULTIPLIER)
      end

      dir.down do
        update_scenarios(1 / INPUT_MULTIPLIER)
      end
    end
  end

  private

  def update_scenarios(multiplier)
    total = Scenario.migratable.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    Scenario.migratable.find_each.with_index do |scenario, index|
      if scenario.user_values.key?(INPUT_KEY)
        scenario.user_values[INPUT_KEY] *= multiplier
        scenario.save(validate: false)

        changed += 1
      end

      say "#{index + 1}/#{total} (#{changed} migrated)" if (index % 1000).zero?
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end
end
