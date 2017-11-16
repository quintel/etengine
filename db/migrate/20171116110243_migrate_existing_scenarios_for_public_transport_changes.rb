class MigrateExistingScenariosForPublicTransportChanges < ActiveRecord::Migration
  def up
    # Old input key -> new input key
    renamed = {
      'transport_useful_demand_car_kms' => 'transport_useful_demand_passenger_kms',
      'transport_useful_demand_truck_kms' => 'transport_useful_demand_freight_tonne_kms',
      'transport_car_using_diesel_mix_efficiency' => 'transport_vehicle_combustion_engine_efficiency',
      'transport_car_using_electricity_efficiency' => 'transport_vehicle_using_electricity_efficiency',
      'transport_car_using_hydrogen_efficiency' => 'transport_vehicle_using_hydrogen_efficiency',
      'transport_useful_demand_planes_efficiency' => 'transport_planes_efficiency',
      'transport_useful_demand_ships_efficiency' => 'transport_ships_efficiency',
      'transport_useful_demand_trains_efficiency' => 'transport_trains_efficiency',
      'transport_train_using_coal_share' => 'transport_passenger_train_using_coal_share',
      'transport_train_using_diesel_share' => 'transport_passenger_train_using_diesel_mix_share',
      'transport_train_using_electricity_share' => 'transport_passenger_train_using_electricity_share',
    }

    # Assume that the share of 'trucks' are the same for 'busses'
    # Assume that the share of 'trains passengers' are the same for 'trains freight'
    assumptions = {
      'transport_passenger_train_using_coal_share' => 'transport_freight_train_using_coal_share',
      'transport_passenger_train_using_diesel_mix_share' => 'transport_freight_train_using_diesel_mix_share',
      'transport_passenger_train_using_electricity_share' => 'transport_freight_train_using_electricity_share',
      'transport_truck_using_compressed_natural_gas_share' => 'transport_bus_using_compressed_natural_gas_share',
      'transport_truck_using_diesel_mix_share' => 'transport_bus_using_diesel_mix_share',
      'transport_truck_using_electricity_share' => 'transport_bus_using_electricity_share',
      'transport_truck_using_gasoline_mix_share' => 'transport_bus_using_gasoline_mix_share',
      'transport_truck_using_hydrogen_share' => 'transport_bus_using_hydrogen_share',
      'transport_truck_using_lpg_share' => 'transport_bus_using_lpg_share',
      'transport_car_using_electricity_share' => 'transport_motorcycle_using_electricity_share'
    }

    corrections = {
      'transport_motorcycle_using_electricity_share' => 'transport_motorcycle_using_gasoline_mix_share'
    }

    # Pruned input keys
    removed = [
      'transport_useful_demand_ship_kms',
      'transport_useful_demand_trains',
      'transport_useful_demand_planes',
      'transport_truck_using_compressed_natural_gas_efficiency'
    ]

    relevant_keys = (removed + assumptions.keys + renamed.keys)

    scenarios = Scenario.where("(`user_values` IS NOT NULL OR `balanced_values` IS NOT NULL) AND (`user_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n' OR `balanced_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n')")

    puts "Need to migrate #{ scenarios.count } scenarios"

    counter = 0
    saved_counter = 0

    scenarios.find_each do |scenario|
      %i(user_values balanced_values).each do |inputs_attribute|
        # Step 0: Initializing
        migrated = scenario.public_send(inputs_attribute)

        overlap = (relevant_keys & migrated.keys)

        next if overlap.empty?

        # Step 1: Translations
        migrated = migrated.each_with_object({}) do |(key, val), obj|
          obj[(renamed[key.to_s] || key.to_s).to_sym] = val
        end

        # Step 2: include assumptions
        migrated = migrated.each_with_object({}) do |(key, val), obj|
          if assumed_key = assumptions[key.to_s]
            obj[assumed_key.to_sym] = val
          end

          obj[key] = val
        end

        # Step 3: Corrections for motorcycles
        migrated = migrated.each_with_object({}) do |(key, val), obj|
          if fix = corrections[key.to_s]
            obj[fix] = (100.0 - val)
          end

          obj[key] = val
        end

        # Step 4: Remove old one's
        migrated = migrated.except(*removed.map(&:to_sym))

        # Actual migration
        scenario.public_send("#{ inputs_attribute }=", migrated)
      end

      if scenario.changed?
        if scenario.valid?
          scenario.save
        else
          a = "#{ DateTime.now } - #{ scenario.id } can't be migrated because '#{ scenario.errors.messages }'\n"

          File.open("#{ Rails.root }/log/scenarios.log", "a") { |f| f.write(a) }

          scenario.save(validate: false)
        end

        saved_counter += 1
      end

      if (counter % 5000) == 1
        puts "At scenario #{ scenario.id } (#{ counter })"
      end

      if (saved_counter % 1000) == 1
        puts "Migrated #{ saved_counter } scenarios"
      end

      counter += 1
    end

    puts "In total migrated #{ saved_counter } scenarios"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
