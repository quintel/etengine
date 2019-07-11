class CleanUpInvalidInputsInScenarios < ActiveRecord::Migration[5.2]
  def up
    total = Scenario.migratable.count
    changed = 0

    say "Checking and migrating #{total} scenarios"

    Scenario.migratable.find_each.with_index do |scenario, index|
      clean_collection!(scenario.user_values)
      clean_collection!(scenario.balanced_values)

      if scenario.changed?
        scenario.save(validate: false, touch: false)
        changed += 1
      end

      if index.positive? && (index % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    say "#{total}/#{total} (#{changed} migrated)"
  end

  private

  def clean_collection!(collection)
    collection.compact!

    collection.each do |key, value|
      if value.is_a?(Rational) || value.is_a?(BigDecimal)
        collection[key] = value.to_f
      end
    end
  end
end
