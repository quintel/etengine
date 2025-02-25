class InitialRemovalOfScenarioTitleAndDescription < ActiveRecord::Migration[7.0]
  def up
    scenarios = Scenario
      .where.not(title: nil).and(Scenario.where.not(title: 'API'))
      .or(Scenario.where.not(description: nil))

    total = scenarios.count
    changed = 0

    scenarios.find_each.with_index do |scenario, index|
      if scenario.title.presence && scenario.title != 'API'
        scenario.metadata['title'] = scenario.title
      end

      if scenario.description.presence
        scenario.metadata['description'] = scenario.description
      end

      scenario.save(validate: false, touch: false)
      changed += 1

      if index.positive? && ((index + 1) % 1000).zero?
        say "#{index + 1}/#{total} (#{changed} migrated)"
      end
    end

    # Rename the columns so that we still have the data in case of rollback. We'll remove them at
    # a later date.
    rename_column(:scenarios, :title, :old_title)
    rename_column(:scenarios, :description, :old_description)
  end

  def down
    rename_column(:scenarios, :old_title, :title)
    rename_column(:scenarios, :old_description, :description)
  end
end
