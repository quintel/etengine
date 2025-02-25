class FixScenarioTitleMetadata < ActiveRecord::Migration[7.0]
  def up
    scenarios = Scenario.where.not(old_title: 'API')

    total = scenarios.count
    changed = 0

    scenarios.find_each.with_index do |scenario, index|
      if scenario.old_title.present? && scenario.old_title != 'API'
        scenario.metadata = { 'title' => scenario.old_title }.merge(scenario.metadata)
        scenario.save(validate: false, touch: false)
        changed += 1
      end

      if index.positive? && ((index + 1) % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end
  end

  def down
  end
end
