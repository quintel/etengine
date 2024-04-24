namespace :hydrogen do
  desc "Updates scenario values for after deploy; reads from JSON"
  task update: :environment do
    changed = 0

    scenario_values = JSON.load(File.read(
      Rails.root.join("tmp/scenario_values.json")
    ))

    Scenario.migratable.find_each.with_index do |scenario, index|
      if index.positive? && ((index + 1) % 1000).zero?
        puts "#{index + 1} (#{changed} updated)"
      end

      next unless scenario_values.key?(scenario.id.to_s)

      new_inputs = scenario_values[scenario.id.to_s]

      new_inputs.each do |key, value|
        scenario.user_values[key] = value
      end

      if scenario.changed?
        scenario.save(validate: false, touch: false)
        changed += 1
      end
    end
  end
end
