require 'etengine/scenario_migration'

class SetEuBuildingStockValues < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  # Only scenarios with these country datasets should be updated
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

  DETACHED_STOCK = {
    'households_number_of_detached_houses_before_1945' => %w[
      households_number_of_detached_houses_before_1945
      households_number_of_semi_detached_houses_before_1945],
    'households_number_of_detached_houses_1945_1964'=> %w[
      households_number_of_detached_houses_1945_1964
      households_number_of_semi_detached_houses_1945_1964],
    'households_number_of_detached_houses_1965_1984'=> %w[
      households_number_of_detached_houses_1965_1984
      households_number_of_semi_detached_houses_1965_1984],
    'households_number_of_detached_houses_1985_2004'=> %w[
      households_number_of_detached_houses_1985_2004
      households_number_of_semi_detached_houses_1985_2004],
    'households_number_of_detached_houses_2005_present'=> %w[
      households_number_of_semi_detached_houses_2005_present
      households_number_of_detached_houses_2005_present],
    'households_number_of_detached_houses_future'=> %w[
      households_number_of_semi_detached_houses_future
      households_number_of_detached_houses_future
    ]
  }.freeze

  # Inputs and corresponding area attribute
  EXISTING_STOCK_MAPPING_DETACHED_SEMI_DETACHED = {
    'households_number_of_detached_houses_before_1945' => 'present_number_of_detached_houses_before_1945',
    'households_number_of_detached_houses_1945_1964' => 'present_number_of_detached_houses_1945_1964',
    'households_number_of_detached_houses_1965_1984' => 'present_number_of_detached_houses_1965_1984',
    'households_number_of_detached_houses_1985_2004' => 'present_number_of_detached_houses_1985_2004',
    'households_number_of_detached_houses_2005_present' => 'present_number_of_detached_houses_2005_present',
    'households_number_of_semi_detached_houses_before_1945' => 'present_number_of_detached_houses_before_1945',
    'households_number_of_semi_detached_houses_1945_1964' => 'present_number_of_detached_houses_1945_1964',
    'households_number_of_semi_detached_houses_1965_1984' => 'present_number_of_detached_houses_1965_1984',
    'households_number_of_semi_detached_houses_1985_2004' => 'present_number_of_detached_houses_1985_2004',
    'households_number_of_semi_detached_houses_2005_present' => 'present_number_of_detached_houses_2005_present'
  }.freeze

  # Inputs and corresponding area attribute
  EXISTING_STOCK_MAPPING = {
    'households_number_of_apartments_before_1945' => 'present_number_of_apartments_before_1945',
    'households_number_of_apartments_1945_1964' => 'present_number_of_apartments_1945_1964',
    'households_number_of_apartments_1965_1984' => 'present_number_of_apartments_1965_1984',
    'households_number_of_apartments_1985_2004' => 'present_number_of_apartments_1985_2004',
    'households_number_of_apartments_2005_present' => 'present_number_of_apartments_2005_present',
    'households_number_of_terraced_houses_before_1945' => 'present_number_of_terraced_houses_before_1945',
    'households_number_of_terraced_houses_1945_1964' => 'present_number_of_terraced_houses_1945_1964',
    'households_number_of_terraced_houses_1965_1984' => 'present_number_of_terraced_houses_1965_1984',
    'households_number_of_terraced_houses_1985_2004' => 'present_number_of_terraced_houses_1985_2004',
    'households_number_of_terraced_houses_2005_present' => 'present_number_of_terraced_houses_2005_present'
  }.freeze


  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|

      # Filter scenarios for the relevant country datasets
      next unless Atlas::Dataset.exists?(scenario.area_code) && COUNTRIES.include?(scenario.area_code)

      set_existing_stock_excl_detached_semi_detached(scenario)
      set_existing_stock_detached_semi_detached(scenario)

    end
  end

  # The numbers of existing buildings should be set to the default value if not set in the scenario.
  def set_existing_stock_excl_detached_semi_detached(scenario)
    # Load scenario defaults fron json file
    scenario_defaults = @defaults[scenario.area_code.to_s]
    unless scenario_defaults
      return
    end

    EXISTING_STOCK_MAPPING.each do |key, area|
      # Obtain default area values
      value = scenario_defaults[area]
      if value.nil?
        next
      end
      # If slider not set, set slider to the dataset default value
      unless scenario.user_values.key?(key)
        scenario.user_values[key] = value
      end
    end
  end

  def set_existing_stock_detached_semi_detached(scenario)
    # Load scenario defaults fron json file
    scenario_defaults = @defaults[scenario.area_code.to_s]
    return unless scenario_defaults

    # First, handle values that are set in the scenario
    DETACHED_STOCK.each do |detached_key, semi_detached_keys|
      value = scenario.user_values[detached_key]
      next if value.nil?

      # Divide the value equally among the mapped keys
      divided_value = value * 0.5
      semi_detached_keys.each do |key|
        # Allocate 0.5 to the first element and 0.5 to the second element
        scenario.user_values[key] = divided_value
      end
    end

    # Second, handle values that are not set in the scenario
    EXISTING_STOCK_MAPPING_DETACHED_SEMI_DETACHED.each do |key, area|
      value = scenario_defaults[area] * 0.5
      next if value.nil?

      unless scenario.user_values.key?(key)
        scenario.user_values[key] = value
      end
    end
  end
end
