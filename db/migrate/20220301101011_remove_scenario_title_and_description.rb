class RemoveScenarioTitleAndDescription < ActiveRecord::Migration[7.0]
  def up
    scenarios = Scenario
      .where.not(title: nil).and(Scenario.where.not(title: 'API'))
      .or(Scenario.where.not(description: nil))

    total = scenarios.count
    changed = 0

    scenarios.find_each.with_index do |scenario|
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

    remove_column(:scenarios, :title)
    remove_column(:scenarios, :description)
  end

  def down
    change_table :scenarios do |t|
      t.string 'title', after: :author
      t.text 'description', after: :title
    end

    Scenario.reset_column_information

    scenarios = Scenario.where.not(metadata: nil)
    total = scenarios.count
    changed = 0

    scenarios.find_each do |scenario|
      if scenario.metadata.key?('title') || scenario.metadata.key('description')
        scenario.title = scenario.metadata['title'].presence
        scenario.description = scenario.metadata['description'].presence

        scenario.save(validate: false, touch: false)

        changed += 1

        if index.positive? && ((index + 1) % 1000).zero?
          say "#{index + 1}/#{total} (#{changed} migrated)"
        end
      end
    end
  end
end
