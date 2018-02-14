class MigrateExistingScenariosForPublicTransportChanges < ActiveRecord::Migration[5.1]
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

    scenarios = Scenario.where(
      '(protected = ? OR created_at >= ?) AND source != ? AND title != ?',
      true, 1.month.ago, 'Mechanical Turk', 'test'
    ).where("(`user_values` IS NOT NULL OR `balanced_values` IS NOT NULL) AND (`user_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n' OR `balanced_values` != '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess {}\n')")

    total = scenarios.count
    started = Time.now
    changes = 0

    puts "Need to migrate #{ total } scenarios"

    scenarios.find_each.with_index do |scenario, idx|
      puts "#{ idx }/#{ total } - #{ changes } changes" if (idx % 1000).zero?

      changed = false

      %i(user_values balanced_values).each do |inputs_attribute|
        # Step 0: Initializing
        migrated = scenario.public_send(inputs_attribute)

        # Step 1: Translations
        renamed.each do |old, new|
          next unless migrated.key?(old)

          changed = true
          migrated[new] = migrated.delete(old)
        end

        # Step 2: include assumptions
        assumptions.each do |from, to|
          next unless migrated.key?(from)

          changed = true
          migrated[to] = migrated[from]
        end

        # Step 3: Corrections for motorcycles
        corrections.each do |from, to|
          next unless migrated.key?(from)

          changed = true
          migrated[to] = 100.0 - migrated.delete(from)
        end

        # Step 4: Remove old ones
        removed.each do |key|
          next unless migrated.key?(key)

          changed = true
          migrated.delete(key)
        end
      end

      if changed
        changes += 1
        scenario.save(validate: false)
      end
    end

    puts "Finished #{ changes } changes"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
