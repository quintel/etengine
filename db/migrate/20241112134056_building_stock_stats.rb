require 'etengine/scenario_migration'

class BuildingStockStats < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  RESIDENCE_KEYS = %w[
    households_number_of_apartments_future
    households_number_of_detached_houses_future
    households_number_of_terraced_houses_future
  ].freeze

  BUILDINGS_KEY = 'buildings_number_of_buildings_future'.freeze

  NEW_NUMBER_OF_RESIDENCES = {
  'SK_slovakia' => 2009796.0,
  'SE_sweden' => 4549981.0,
  'BG_bulgaria' => 3047289.0,
  'FI_finland' => 2906738.0,
  'MT_malta' => 242604.0,
  'IT_italy' => 28318809.0,
  'CZ_czechia' => 4800690.0,
  'AT_austria' => 4330099.0,
  'EU27_european_union_27_countries' => 208874408.0,
  'EL_greece' => 5587366.0,
  'SI_slovenia' => 768518.0,
  'FR_france' => 34855205.0,
  'IE_ireland' => 2059537.0,
  'CY_cyprus' => 429509.0,
  'DK_denmark' => 2642473.0,
  'ES_spain' => 22444755.0,
  'HU_hungary' => 4040036.0,
  'PL_poland' => 14653084.0,
  'LV_latvia' => 932282.0,
  'BE_belgium' => 5138825.0,
  'LU_luxembourg' => 228784.0,
  'HR_croatia' => 1967594.0,
  'EE_estonia' => 692933.0,
  'DE_germany' => 39663075.0,
  'PT_portugal' => 5252520.0,
  'LT_lithuania' => 1268131.0,
  'RO_romania' => 8983019.0
  }

  NEW_NUMBER_OF_BUILDINGS = {
  'SK_slovakia' => 7464.0,
  'SE_sweden' => 277190.0,
  'BG_bulgaria' => 89643.0,
  'FI_finland' => 75078.0,
  'MT_malta' => 14222.0,
  'IT_italy' => 536294.0,
  'CZ_czechia' => 121661.0,
  'AT_austria' => 60345.0,
  'EU27_european_union_27_countries' => 10111171.0,
  'EL_greece' => 549100.0,
  'SI_slovenia' => 82458.0,
  'FR_france' => 1624002.0,
  'IE_ireland' => 112514.0,
  'CY_cyprus' => 263626.0,
  'DK_denmark' => 232155.0,
  'ES_spain' => 1250490.0,
  'HU_hungary' => 64321.0,
  'PL_poland' => 854115.0,
  'LV_latvia' => 82226.0,
  'BE_belgium' => 660783.0,
  'LU_luxembourg' => 11730.0,
  'HR_croatia' => 768894.0,
  'EE_estonia' => 29595.0,
  'DE_germany' => 1116312.0,
  'PT_portugal' => 624481.0,
  'LT_lithuania' => 70450.0,
  'RO_romania' => 324267.0
  }

  def up
    migrate_scenarios do |scenario|
      next unless Atlas::Dataset.exists?(scenario.area_code) &&
                  NEW_NUMBER_OF_BUILDINGS.key?(scenario.area_code)

      residences(scenario)
      buildings(scenario)
    end
  end

  private

  def residences(scenario)
    RESIDENCE_KEYS.each do |key|
      next unless scenario.user_values.key?(key)

      value = scenario.user_values[key]
      reference_value = NEW_NUMBER_OF_RESIDENCES[scenario.area_code.to_s]

      if value > reference_value
        puts "Scenario ID: #{scenario.id} | Area Code: #{scenario.area_code} | " \
             "Key: #{key} | Value: #{value} | Reference: #{reference_value}"
      end
    end
  end

  def buildings(scenario)
    if scenario.user_values.key?(BUILDINGS_KEY)
      value = scenario.user_values[BUILDINGS_KEY]
      reference_value = NEW_NUMBER_OF_BUILDINGS[scenario.area_code.to_s]

      if value > reference_value
        puts "Scenario ID: #{scenario.id} | Area Code: #{scenario.area_code} | " \
             "Key: #{BUILDINGS_KEY} | Value: #{value} | Reference: #{reference_value}"
      end
    end
  end
end
