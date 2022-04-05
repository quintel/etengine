require 'etengine/scenario_migration'
require 'csv'

class TrucksAndVans < ActiveRecord::Migration[7.0]
  include ETEngine::ScenarioMigration

  TRUCKS_INPUT = 'transport_trucks_share'
  VANS_INPUT = 'transport_vans_share'

  TECHNOLOGIES = %w[
    using_compressed_natural_gas_share
    using_diesel_mix_share
    using_electricity_share
    using_gasoline_mix_share
    using_hydrogen_share
    using_lng_mix_share
  ].freeze

  def up
    @trucks_shares = TrucksCSV.new("#{__dir__}/20220311141452_trucks_and_vans/truck_shares.csv")

    migrate_scenarios do |scenario|
      next unless Atlas::Dataset.exists?(scenario.area_code)

      # Calculate new shares for trucks and vans in the application split, based on present share
      recalculate_application_split(scenario) if scenario.user_values.key?(TRUCKS_INPUT)

      # Copy the technology splits from trucks to vans
      copy_tech_split(scenario)
    end
  end

  def recalculate_application_split(scenario)
    share_of_trucks_in_trucks_and_vans = @trucks_shares.share_for(scenario.area_code)
    old_truck_input = scenario.user_values[TRUCKS_INPUT]
    scenario.user_values[VANS_INPUT] = (1 - share_of_trucks_in_trucks_and_vans) * old_truck_input
    scenario.user_values[TRUCKS_INPUT] = share_of_trucks_in_trucks_and_vans * old_truck_input
  end

  def copy_tech_split(scenario)
    untouched = []
    sum = 0.0

    TECHNOLOGIES.each do |tech|
      if scenario.user_values.key?(tech_key(tech, 'truck'))
        scenario.user_values[tech_key(tech, 'van')] = scenario.user_values[tech_key(tech, 'truck')]
        sum += scenario.user_values[tech_key(tech, 'truck')]
      elsif scenario.balanced_values.key?(tech_key(tech, 'truck'))
        scenario.balanced_values[tech_key(tech, 'van')] = scenario.balanced_values[tech_key(tech, 'truck')]
        sum += scenario.balanced_values[tech_key(tech, 'truck')]
      else
        untouched << tech
      end
    end

    # Quick balancing for when not all inputs were copied
    if untouched and untouched.length != TECHNOLOGIES.length
      if 99.9 < sum and sum < 100.1
        # In case of rounding issues I took an 0.1 boundry
        untouched.each { |tech| scenario.balanced_values[tech_key(tech, 'van')] = 0 }
      else
        avg_share_left = (100.0 - sum) / untouched.length
        untouched.each { |tech| scenario.balanced_values[tech_key(tech, 'van')] = avg_share_left }
      end
    end
  end

  # Input key for the technology splits. Truck LNG is mapped to vans LPG.
  def tech_key(tech, vehicle)
    tech = 'using_lpg_share' if tech == 'using_lng_mix_share' and vehicle == 'van'

    "transport_#{vehicle}_#{tech}"
  end

  class TrucksCSV
    def initialize(path)
      table = File.open(path) do |file|
        CSV.parse(file, converters: [:float])
      end

      @mapping = {}
      table.each do |a|
        @mapping[a[0]] = a[1]
      end
    end

    def share_for(dataset)
      return @mapping[dataset] if @mapping.key? dataset

      1.0
    end
  end

  # Method used to generate the trucks shares CSV
  # def caclulate_shares
  #   trucks = Input.by_name(TRUCKS_INPUT).first
  #   vans = Input.by_name(VANS_INPUT).first

  #   f = File.new('truck_shares.csv', 'w')
  #   f << "dataset,share_of_trucks_in_trucks_and_vans\n"

  #   Atlas::Dataset.all.each do |ds|
  #     puts ds.area
  #     # create scenario
  #     scenario = Scenario.new(area_code: ds.area)

  #     trucks_base_share = trucks.start_value_for(scenario)
  #     puts '  - truck start value unknown' unless trucks_base_share
  #     vans_base_share = vans.start_value_for(scenario)
  #     puts '  - vans start value unknown' unless vans_base_share
  #     total_base_share = trucks_base_share + vans_base_share

  #     share_of_trucks_in_trucks_and_vans = trucks_base_share / total_base_share

  #     f << "#{ds.area},#{share_of_trucks_in_trucks_and_vans}\n"
  #   end


  #   f.close
  # end
end
