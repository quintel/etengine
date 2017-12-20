class UpdateBuildingsSolarPvProduction < ActiveRecord::Migration
  INPUTS = %w[
    buildings_solar_pv_solar_radiation_market_penetration
    number_of_buildings
  ].freeze

  SOLAR_KEY = :buildings_solar_pv_solar_radiation_market_penetration

  def up
    update_each_scenario do |scenario|
      scenario.user_values[SOLAR_KEY] /= growth_factor(scenario)
    end
  end

  def down
    update_each_scenario do |scenario|
      scenario.user_values[SOLAR_KEY] *= growth_factor(scenario)
    end
  end

  private

  def update_each_scenario
    # Only update protected scenarios or those created in the past month (older
    # unsaved scenarios are likely abandoned). Skip mturk scenarios.
    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ?',
      true, 1.month.ago, 'Mechanical Turk'
    )

    say_with_time "Updating #{scenarios.length} candidate scenarios" do
      scenarios.find_each.with_index do |scenario, index|
        if affected_scenario?(scenario)
          yield(scenario)
          scenario.save!
        end

        say "| #{ index }" if (index % 500).zero? && !index.zero?
      end

      say "| #{scenarios.length}"
    end
  end

  def affected_scenario?(scenario)
    # Neither input is part of a share group, so the keys will not appear in the
    # :balanced_values collection
    INPUTS.all? { |key| scenario.user_values.key?(key) }
  end

  # See: https://github.com/quintel/etsource/issues/1330#issuecomment-352809844
  def growth_factor(scenario)
    area = scenario.area
    buildings = scenario.user_values[:number_of_buildings]

    (buildings / 100 + 1) ** (scenario.end_year - area[:analysis_year])
  end
end
