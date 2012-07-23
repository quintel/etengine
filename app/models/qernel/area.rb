module Qernel

  class Area
    include DatasetAttributes

    ATTRIBUTES_USED = [
      :area,
      :co2_price,
      :co2_percentage_free,
      :el_import_capacity,
      :el_export_capacity,
      :co2_emission_1990,
      :co2_emission_2009,
      :co2_emission_electricity_1990,
      :roof_surface_available_pv,
      :areable_land,
      :offshore_suitable_for_wind,
      :onshore_suitable_for_wind,
      :coast_line,
      :available_land,
      :land_available_for_solar,
      :km_per_car,
      :import_electricity_primary_demand_factor,
      :export_electricity_primary_demand_factor,
      :capacity_buffer_in_mj_s,
      :capacity_buffer_decentral_in_mj_s,
      :km_per_truck,
      :number_households,
      :number_inhabitants,
      :annual_infrastructure_cost_gas,
      :annual_infrastructure_cost_electricity,
      :annual_infrastructure_cost_electricity,
      :annual_infrastructure_cost_gas,
      :has_mountains,
      :has_coastline,
      :use_network_calculations,
      :has_lignite,
      :percentage_of_new_houses,
      :recirculation,
      :heat_recovery,
      :ventilation_rate,
      :entity,
      :market_share_motion_detection,
      :market_share_daylight_control,
      :roof_surface_available_pv_buildings,
      :insulation_level_buildings,
      :insulation_level_new_houses,
      :insulation_level_existing_houses,
      :has_buildings,
      :has_other,
      :has_solar_csp,
      :has_old_technologies,
      :cold_network_potential,
      :has_cold_network,
      :input_values,
      # Special attribute, does not exist in Area columns, has to be added extra in Area#dataset_attributes
      :number_of_existing_households,
      :economic_multiplier,
      :employment_local_fraction,
      :employment_fraction_production,
      :has_employment,
      :has_merit_order
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
