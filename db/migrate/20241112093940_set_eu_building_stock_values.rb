require 'etengine/scenario_migration'

class SetEuBuildingStockValues < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  # Only scenarios made with these country datasets should be updated
  COUNTRIES = %w[
    AT_austria
    BE_belgium
    BG_bulgaria
    HR_croatia
    CY_cyprus
    CZ_czechia
    DK_denmark
    EE_estonia
    EU27_european_union_27_countries
    FI_finland
    FR_france
    DE_germany
    EL_greece
    HU_hungary
    IE_ireland
    IT_italy
    LV_latvia
    LT_lithuania
    LU_luxembourg
    MT_malta
    PL_poland
    PT_portugal
    RO_romania
    SK_slovakia
    SI_slovenia
    ES_spain
    SE_sweden
  ].freeze

  EXISTING_STOCK_SEMI_DETACHED = %w[
    households_number_of_semi_detached_houses_before_1945
    households_number_of_semi_detached_houses_1945_1964
    households_number_of_semi_detached_houses_1965_1984
    households_number_of_semi_detached_houses_1985_2004
    households_number_of_semi_detached_houses_2005_present
  ].freeze

  # Inputs and corresponding area attribute
  EXISTING_STOCK_MAPPING = %w[
    households_number_of_apartments_before_1945
    households_number_of_apartments_1945_1964
    households_number_of_apartments_1965_1984
    households_number_of_apartments_1985_2004
    households_number_of_apartments_2005_present
    households_number_of_detached_houses_before_1945
    households_number_of_detached_houses_1945_1964
    households_number_of_detached_houses_1965_1984
    households_number_of_detached_houses_1985_2004
    households_number_of_detached_houses_2005_present
    households_number_of_terraced_houses_before_1945
    households_number_of_terraced_houses_1945_1964
    households_number_of_terraced_houses_1965_1984
    households_number_of_terraced_houses_1985_2004
    households_number_of_terraced_houses_2005_present
    buildings_number_of_buildings_present
  ].freeze

  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|

      # Filter scenarios for the relevant country datasets
      next unless Atlas::Dataset.exists?(scenario.area_code) && COUNTRIES.include?(scenario.area_code)

      set_existing_stock_excl_semi_detached(scenario)
      set_semi_detached(scenario)

    end
  end

  # The numbers of existing buildings should be set according to the slider settings. If the slider is
  # set, it should be set to the set value. If slider is not set, then it should be set to the default value.
  def set_existing_stock_excl_semi_detached(scenario)
    #If slider is set, set value of slider to set value
    EXISTING_STOCK_MAPPING.each do |key|

      # Check if key is not set and set to default value
      if not scenario.user_values.key?(key)
        value = @defaults[scenario.area_code.to_s][key]
        scenario.user_values[key] = value
      end
    end
  end

  # The new country datasets have > 0 values for number of semi-detached houses  whereas in old scenarios
  # values for these inputs were set to zero and could not be set by users. To retain the outcomes
  # of older scenarios  the inputs are set to 0.
  def set_semi_detached(scenario)
    EXISTING_STOCK_SEMI_DETACHED.each do |key|
      scenario.user_values[key] = 0.0
    end
  end
end
