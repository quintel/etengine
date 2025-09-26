require 'etengine/scenario_migration'

class UsefulHeatDemand2023 < ActiveRecord::Migration[7.1]
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


  def up
    @defaults = JSON.load(File.read(
      Rails.root.join("db/migrate/#{File.basename(__FILE__, '.rb')}/dataset_values.json")
    ))
    migrate_scenarios do |scenario|
      next unless scenario.area_code.start_with?('GM', 'ES', 'PV')
      next if scenario.area_code == 'ES_spain'
      next unless Atlas::Dataset.exists?(scenario.area_code)
      migrate_useful_heat_demand(scenario)
    end

  end

  private

  def get_old_area_code(current_area_code)
    OLD_AREA_CODE_MAPPING[current_area_code] || current_area_code
  end

  def user_key_to_default_key(user_key)
    if user_key.start_with?('households_insulation_level_')
      user_key.sub('households_insulation_level_', 'typical_useful_demand_for_space_heating_')
    else
      user_key
    end
  end

  def migrate_useful_heat_demand(scenario)
    HOUSING_TYPES.each do |housing_type|
      CONSTRUCTION_PERIODS.each do |construction_period|
        user_key = "households_insulation_level_#{housing_type}_#{construction_period}"

        next unless scenario.user_values.key?(user_key)

        default_key = user_key_to_default_key(user_key)
        old_area_code = get_old_area_code(scenario.area_code)

        # Skip if no defaults for this area
        next unless @defaults[old_area_code]&.key?(default_key)

        default_insulation = @defaults[old_area_code][default_key]
        default_insulation_23 = scenario.area[user_key]
        user_insulation = scenario.user_values[user_key]

        # Skip if area data is missing
        next if default_insulation_23.nil?

        if user_insulation < default_insulation
          scaling_factor = user_insulation / default_insulation
          scenario.user_values[user_key] = default_insulation_23 * scaling_factor
          scenario.user_values[user_key] = [1, scenario.user_values[user_key]].max
        end
      end
    end
  end
end
