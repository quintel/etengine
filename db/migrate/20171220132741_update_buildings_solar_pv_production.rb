class UpdateBuildingsSolarPvProduction < ActiveRecord::Migration
  INPUTS = %w[
    buildings_solar_pv_solar_radiation_market_penetration
    number_of_buildings
  ].freeze

  SOLAR_KEY = :buildings_solar_pv_solar_radiation_market_penetration

  # Cannot access area data inside migrations as Atlas/ETSource data hasn't been
  # linked.
  ANALYSIS_YEARS = {
    almere: 2015,
    baarland: 2015,
    be: 2013,
    br: 2013,
    de: 2012,
    de_biezen: 2013,
    drenthe: 2013,
    dronten: 2015,
    es: 2012,
    eu: 2011,
    example: 2011,
    flevoland: 2015,
    fr: 2012,
    friesland: 2015,
    gemeente_groningen: 2015,
    goes: 2015,
    groningen: 2013,
    lelystad: 2015,
    nl: 2015,
    nl2012: 2012,
    nl2013: 2013,
    noorderplantsoen: 2013,
    noordoostpolder: 2015,
    paddepoel_noord: 2013,
    pl: 2012,
    stedendriehoek: 2015,
    uk: 2012,
    urk: 2015,
    zeeland: 2015,
    zeewolde: 2015
  }.freeze

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
          scenario.save(validate: false)
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
    buildings = scenario.user_values[:number_of_buildings]

    (buildings / 100 + 1) **
      (scenario.end_year - ANALYSIS_YEARS[scenario.area_code.to_sym])
  end
end
