require 'etengine/scenario_migration'

class BuildingsAndHouseholds2023 < ActiveRecord::Migration[7.1]
  include ETEngine::ScenarioMigration

  # Reverse mapping from new area codes to old area codes
  OLD_AREA_CODE_MAPPING = {
    # === Province rename ===
    "PV21_fryslan" => "PV21_friesland",

    # === RES → ES renames ===
    "ES01_groningen" => "RES08_groningen",
    "ES02_friesland" => "RES06_regio_friesland",
    "ES03_drenthe" => "RES03_regio_drenthe",
    "ES04_twente" => "RES27_twente",
    "ES05_west_overijssel" => "RES29_west_overijssel",
    "ES06_flevoland" => "RES04_flevoland",
    "ES07_achterhoek" => "RES01_achterhoek",
    "ES08_arnhem_nijmegen" => "RES23_arnhem_nijmegen",
    "ES09_foodvalley" => "RES05_foodvalley",
    "ES10_noord_veluwe" => "RES18_noord_veluwe",
    "ES11_fruitdelta_rivierenland" => "RES25_rivierenland_fruitdelta",
    "ES12_stedendriehoek" => "RES26_cleantechregio",
    "ES13_amersfoort" => "RES22_amersfoort",
    "ES14_u16" => "RES24_u16",
    "ES15_noord_holland_noord" => "RES16_noord_holland_noord",
    "ES16_noord_holland_zuid" => "RES17_noord_holland_zuid",
    "ES17_alblasserwaard" => "RES21_alblasserwaard",
    "ES18_drechtsteden" => "RES02_drechtsteden",
    "ES19_goeree_overflakkee" => "RES07_goeree_overflakkee",
    "ES20_hoeksche_waard" => "RES10_hoeksewaard",
    "ES21_holland_rijnland" => "RES11_holland_rijnland",
    "ES22_midden_holland" => "RES14_midden_holland",
    "ES23_rotterdam_den_haag" => "RES13_rotterdam_denhaag",
    "ES24_zeeland" => "RES30_zeeland",
    "ES25_hart_van_brabant" => "RES09_hart_van_brabant",
    "ES26_metropoolregio_eindhoven" => "RES12_metropoolregio_eindhoven",
    "ES27_noordoost_brabant" => "RES20_noord_oost_brabant",
    "ES28_west_brabant" => "RES28_west_brabant",
    "ES29_noord_en_midden_limburg" => "RES19_noord_en_midden_limburg",
    "ES30_zuid_limburg" => "RES31_zuid_limburg"
  }.freeze

  # Housing types
  HOUSING_TYPES = %w[
    apartments
    semi_detached_houses
    detached_houses
    terraced_houses
  ].freeze

  # Construction periods
  CONSTRUCTION_PERIODS = %w[
    before_1945
    1945_1964
    1965_1984
    1985_2004
    2005_present
    future
  ].freeze

  BUILDINGS_PRESENT = 'buildings_number_of_buildings_present'.freeze
  BUILDINGS_FUTURE = 'buildings_number_of_buildings_future'.freeze
  BUILDINGS_ATTRIBUTE = 'present_number_of_buildings'.freeze
  BUILDINGS_OLD_SIZE = 293.627703981492.freeze
  BUILDINGS_SIZE_ATTRIBUTE = 'area_per_building_residence_equivalent'.freeze

  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))

    migrate_scenarios do |scenario|
      next unless scenario.area_code.start_with?('GM', 'ES', 'PV')
      next if scenario.area_code == 'ES_spain'
      next unless Atlas::Dataset.exists?(scenario.area_code)
      
      migrate_buildings(scenario)
      migrate_households(scenario)
    end
  end

  private

  def get_old_area_code(current_area_code)
    OLD_AREA_CODE_MAPPING[current_area_code] || current_area_code
  end

  def user_key_to_default_key(user_key)
    if user_key.start_with?('households_number_of_') && user_key.end_with?('_future')
      "present_number_of_residences"
    elsif user_key.start_with?('households_number_of_')
      user_key.sub('households_number_of_', 'present_number_of_')
    else
      user_key
    end
  end

  def migrate_buildings(scenario)
    # Present
    if scenario.user_values.key?(BUILDINGS_PRESENT)
      old_area_code = get_old_area_code(scenario.area_code)
      old_default = @defaults[old_area_code][BUILDINGS_ATTRIBUTE]

      # If user value was set below the old default/max
      # Then calculate the percentage of change in the input
      # And multiply that with the new default/max
      if scenario.user_values[BUILDINGS_PRESENT] < old_default
        scenario.user_values[BUILDINGS_PRESENT] = (
          scenario.area[BUILDINGS_ATTRIBUTE] * (               # new default/max
            scenario.user_values[BUILDINGS_PRESENT] / old_default       # change
          )
        )
      end
    end

    # Future
    if scenario.user_values.key?(BUILDINGS_FUTURE)
      # When buildings were added (newly built)
      # Then multiply those by the change in size
      scenario.user_values[BUILDINGS_FUTURE] = (
        scenario.user_values[BUILDINGS_FUTURE] * (
          BUILDINGS_OLD_SIZE / scenario.area[BUILDINGS_SIZE_ATTRIBUTE]
        )
      )
    end
  end

  def migrate_households(scenario)
    HOUSING_TYPES.each do |housing_type|
      CONSTRUCTION_PERIODS.each do |construction_period|
        user_key = "households_number_of_#{housing_type}_#{construction_period}"

        next unless scenario.user_values.key?(user_key)

        default_key = user_key_to_default_key(user_key)
        old_area_code = get_old_area_code(scenario.area_code)
        default_houses = @defaults[old_area_code][default_key]
        default_houses_23 = scenario.area[default_key]
        user_houses = scenario.user_values[user_key]
        if user_houses < default_houses
          scenario.user_values[user_key] = [user_houses, default_houses_23].min
        end
      end
    end
  end
end
