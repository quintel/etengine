module Qernel

  class Area
    include DatasetAttributes

    ATTRIBUTES_USED = [
      # Special attribute, does not exist in Area columns, has to be added extra in Area#dataset_attributes
      :annual_infrastructure_cost_electricity,
      :annual_infrastructure_cost_electricity,
      :annual_infrastructure_cost_gas,
      :annual_infrastructure_cost_gas,
      :area,
      :areable_land,
      :available_land,
      :capacity_buffer_decentral_in_mj_s,
      :capacity_buffer_in_mj_s,
      :co2_emission_1990,
      :co2_emission_2009,
      :co2_emission_electricity_1990,
      :co2_percentage_free,
      :co2_price,
      :coast_line,
      :cold_network_potential,
      :economic_multiplier,
      :el_export_capacity,
      :el_import_capacity,
      :employment_fraction_production,
      :employment_local_fraction,
      :entity,
      :export_electricity_primary_demand_factor,
      :has_buildings,
      :has_climate,
      :has_coastline,
      :has_cold_network,
      :has_electricity_storage,
      :has_employment,
      :has_lignite,
      :has_merit_order,
      :has_metal,
      :has_mountains,
      :has_old_technologies,
      :has_other,
      :has_solar_csp,
      :has_import_export,
      :heat_recovery,
      :import_electricity_primary_demand_factor,
      :input_values,
      :technical_lifetime_insulation,
      :insulation_level_new_houses_min,
      :insulation_level_new_houses_max,
      :insulation_level_old_houses_min,
      :insulation_level_old_houses_max,
      :insulation_level_buildings_min,
      :insulation_level_buildings_max,
      :buildings_insulation_constant_1,
      :buildings_insulation_constant_2,
      :buildings_insulation_cost_constant,
      :buildings_insulation_employment_constant,
      :old_houses_insulation_constant_1,
      :old_houses_insulation_constant_2,
      :old_houses_insulation_cost_constant,
      :old_houses_insulation_employment_constant,
      :new_houses_insulation_constant_1,
      :new_houses_insulation_constant_2,
      :new_houses_insulation_cost_constant,
      :new_houses_insulation_employment_constant,
      :insulation_level_buildings,
      :insulation_level_existing_houses,
      :insulation_level_new_houses,
      :km_per_car,
      :km_per_truck,
      :land_available_for_solar,
      :man_hours_per_man_year, # MAN_HOURS_PER_MAN_YEAR
      :man_year_per_mj_insulation_per_year, #MAN_YEAR_PER_MJ_INSULATION_PER_YEAR
      :market_share_daylight_control,
      :market_share_motion_detection,
      :number_households,
      :number_of_old_residences,
      :number_of_new_residences,
      :number_buildings,
      :number_inhabitants,
      :number_of_existing_households,
      :offshore_suitable_for_wind,
      :onshore_suitable_for_wind,
      :percentage_of_new_houses,
      :recirculation,
      :roof_surface_available_pv,
      :roof_surface_available_pv_buildings,
      :use_network_calculations,
      :enabled,
      :ventilation_rate,
      :analysis_year
    ]

    dataset_accessors ATTRIBUTES_USED

    attr_accessor :graph
    attr_reader :dataset_key, :key

    def initialize(graph = nil)
      self.graph = graph unless graph.nil?
      @dataset_key = @key = :area_data
    end

    # Remove when we replace :area with :area_code
    def area_code
      area
    end

    def inspect
      "<Area #{area_code}>"
    end

    # ----- attributes/methods still used in gqueries. should be properly added to etsource or change gqueries.

    def co2_emission_1990_billions
      co2_emission_1990 * BILLIONS
    end

    # ?!
    def manure_available_in_pj=(param)
      param
    end

    # ?!
    def manure_available_in_pj
      0.0
    end
  end
end
