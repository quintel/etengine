class AddMigrationForCostsCoalAndCostsOil < ActiveRecord::Migration[5.1]
  EXCHANGE_RATE_DOLLAR_EURO = 1.06934
  RELEVANT_KEYS = %i(costs_coal costs_oil)

  def change
    count = 0
    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, 1.month.ago, 'Mechanical Turk', 'test'
    )

    puts "#{ Time.now } | Need to migrate: #{ scenarios.count } scenarios"

    scenarios.find_each do |scenario|
      next if scenario.user_values.slice(*RELEVANT_KEYS).empty?

      scenario.user_values = scenario.user_values.merge(
        scenario.user_values.slice(*RELEVANT_KEYS).each_with_object({}) do |(key, val), obj|
          obj[key] = val * EXCHANGE_RATE_DOLLAR_EURO
        end
      )

      puts "#{ Time.now } | #{ scenario.id } (#{ count })" if (count % 100).zero?

      scenario.save
      count += 1
    end
  end
end
