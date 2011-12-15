module Etsource
  class Constants
    # This is to quickly prototype. has to find a better place
    # because it is both accessed by etsource dataset.yml files and frontend code
    HOUSEHOLDS_HOT_WATER = {
      :coal => %w[coal_boiler_households_energetic],
      :crude_oil => %w[oil_boiler_households_energetic],
      :natural_gas => %w[gas_boiler_households_energetic cv_hot_water_households_energetic fuel_cell_chp_households_energetic micro_chp_hot_water_households_energetic],
      :biomass => %w[biomass_boiler_households_energetic],
      :electricity => %w[heatpump_boiler_households_energetic electric_boiler_households_energetic]#,
      #:steam_hot_water => %w[heatpump_boiler_using_city_heat_households_energetic]
    }
  end
end