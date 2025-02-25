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

  # All relevant building stock keys that could've been set
  BUILDING_STOCK_KEYS = %w[
    households_number_of_detached_houses_before_1945
    households_number_of_detached_houses_1945_1964
    households_number_of_detached_houses_1965_1984
    households_number_of_detached_houses_1985_2004
    households_number_of_detached_houses_2005_present
    households_number_of_detached_houses_future
    households_number_of_apartments_before_1945
    households_number_of_apartments_1945_1964
    households_number_of_apartments_1965_1984
    households_number_of_apartments_1985_2004
    households_number_of_apartments_2005_present
    households_number_of_apartments_future
    households_number_of_terraced_houses_before_1945
    households_number_of_terraced_houses_1945_1964
    households_number_of_terraced_houses_1965_1984
    households_number_of_terraced_houses_1985_2004
    households_number_of_terraced_houses_2005_present
    households_number_of_terraced_houses_future
  ].freeze

  # Mapping of keys to area attribute
  BUILDING_STOCK_EXISTING_MAPPING = {
    'households_number_of_detached_houses_before_1945' => 'present_number_of_detached_houses_before_1945',
    'households_number_of_detached_houses_1945_1964' => 'present_number_of_detached_houses_1945_1964',
    'households_number_of_detached_houses_1965_1984' => 'present_number_of_detached_houses_1965_1984',
    'households_number_of_detached_houses_1985_2004' => 'present_number_of_detached_houses_1985_2004',
    'households_number_of_detached_houses_2005_present' => 'present_number_of_detached_houses_2005_present',
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

  # Mapping of detached keys for allocation to detached and semi detached
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
      households_number_of_detached_houses_2005_present]
  }.freeze

  # Future building stock keys incl mapping for detached
  BUILDING_STOCK_FUTURE = {
    'households_number_of_detached_houses_future' => %w[
      households_number_of_detached_houses_future
      households_number_of_semi_detached_houses_future],
    'households_number_of_apartments_future' => %w[
      households_number_of_apartments_future],
    'households_number_of_terraced_houses_future' => %w[
      households_number_of_terraced_houses_future]
}.freeze

  DETACHED_FUTURE = 'households_number_of_detached_houses_future'

  # Future stock slider cannot be set higher than total present nr of residences
  MAX_FUTURE_STOCK = 'present_number_of_residences'


  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|

      # Filter scenarios for the relevant country datasets
      next unless Atlas::Dataset.exists?(scenario.area_code) && COUNTRIES.include?(scenario.area_code)
      # Check if one of building stock sliders is touched, then some correction should be done to set keys
      next unless BUILDING_STOCK_KEYS.any? { |key| scenario.user_values.key?(key)}

      set_existing_stock(scenario)
      set_future_stock(scenario)

    end
  end

  def set_existing_stock(scenario)
    # Obtain old default area values
    scenario_defaults = @defaults[scenario.area_code.to_s]

    BUILDING_STOCK_EXISTING_MAPPING.each do |key, area|
      # Skip if key is not set in user_values
      next unless scenario.user_values.key?(key)

      # Obtain old default area value
      old_default_value = scenario_defaults[area]
      next if old_default_value.nil?

      # Obtain new default area value
      new_default_value = scenario.area[area]
      next if new_default_value.nil?

      set_value = scenario.user_values[key]
      relative_change = (old_default_value == 0) ? 1 : (set_value / old_default_value)
      new_value = relative_change * new_default_value

      if DETACHED_STOCK.key?(key)
        DETACHED_STOCK[key].each do |item|
          scenario.user_values[item] = new_value
        end
      else
        scenario.user_values[key] = new_value
      end
    end
  end

  def set_future_stock(scenario)
    BUILDING_STOCK_FUTURE.each do |main_key,allocation_keys|
      # Skip if key is not set in user_values
      next unless scenario.user_values.key?(main_key)

      set_value = scenario.user_values[main_key]
      new_max_value = scenario.area[MAX_FUTURE_STOCK]

      allocation_keys.each do |key|
        if main_key == DETACHED_FUTURE
          set_future_stock_semi_and_detached(scenario, key, set_value, new_max_value)
        else
          set_future_stock_terraced_apartments(scenario, key, set_value, new_max_value)
        end
      end
    end
  end

  # For detached houses, the set value will be half allocated to detached, half to semi detached
  def set_future_stock_semi_and_detached(scenario, key, set_value, new_max_value)
    corrected_set_value = set_value * 0.5
    if corrected_set_value > new_max_value
      scenario.user_values[key] = new_max_value
    else
      scenario.user_values[key] = corrected_set_value
    end
  end

  def set_future_stock_terraced_apartments(scenario, key, set_value, new_max_value)
    if set_value > new_max_value
      scenario.user_values[key] = new_max_value
    end
  end
end
