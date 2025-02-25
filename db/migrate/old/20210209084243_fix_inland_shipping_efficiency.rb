require 'etengine/scenario_migration'

class FixInlandShippingEfficiency < ActiveRecord::Migration[5.2]
  include ETEngine::ScenarioMigration

  def up
    migrate_scenarios do |scenario|
      if ( scenario.area_code == "nl" &&
         scenario.user_values["transport_trucks_share"].to_f > 83.2 && scenario.user_values["transport_trucks_share"].to_f < 83.6 &&
         scenario.user_values["transport_freight_trains_share"].to_f > 5.0 && scenario.user_values["transport_freight_trains_share"].to_f < 5.4 &&
         scenario.user_values["transport_ships_share"].to_f > 11.2 && scenario.user_values["transport_ships_share"].to_f < 11.6
         )

         scenario.user_values.delete("transport_trucks_share")
         scenario.user_values.delete("transport_freight_trains_share")
         scenario.user_values.delete("transport_ships_share")
      end
    end
  end
end
