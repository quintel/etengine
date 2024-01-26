# frozen_string_literal: true

class Benchmarks

  class Utils

    class Curve

      Curve = Struct.new(:original_filename, :tempfile)

      class << self
        def add_curve_to_scenario(scenario, curve_name)
          handler = ::CurveHandler::AttachService.new(
            ::CurveHandler::Config.find(curve_name),
            create_temp_curve_file(curve_name),
            scenario,
            {}
          )

          # Attach the curve to the scenario
          handler.call
        end

        def create_temp_curve_file(name)
          curve = Curve.new("#{name}.csv", Tempfile.new(name))
          curve.tempfile.write(curve_contents)

          curve
        end

        def curve_names
          # All possible curve names as of writing
          %w[
          agriculture_electricity
          buildings_appliances buildings_cooling
          electric_buses electric_planes electric_ships electric_trucks electric_vans
          electric_vehicle_profile_1 electric_vehicle_profile_2 electric_vehicle_profile_3 electric_vehicle_profile_4 electric_vehicle_profile_5
          geothermal_heat
          households_appliances households_cooling households_hot_water
          hydrogen_export hydrogen_import
          industry_chemicals_electricity industry_chemicals_heat
          industry_fertilizers_electricity industry_fertilizers_heat
          industry_ict
          industry_metals_electricity industry_metals_heat
          industry_other_electricity industry_other_heat
          industry_refineries_electricity industry_refineries_heat
          interconnector_10_export_availability interconnector_10_import_availability interconnector_10_price
          interconnector_11_export_availability interconnector_11_import_availability interconnector_11_price
          interconnector_12_export_availability interconnector_12_import_availability interconnector_12_price
          interconnector_1_export_availability interconnector_1_import_availability interconnector_1_price
          interconnector_2_export_availability interconnector_2_import_availability interconnector_2_price
          interconnector_3_export_availability interconnector_3_import_availability interconnector_3_price
          interconnector_4_export_availability interconnector_4_import_availability interconnector_4_price
          interconnector_5_export_availability interconnector_5_import_availability interconnector_5_price
          interconnector_6_export_availability interconnector_6_import_availability interconnector_6_price
          interconnector_7_export_availability interconnector_7_import_availability interconnector_7_price
          interconnector_8_export_availability interconnector_8_import_availability interconnector_8_price
          interconnector_9_export_availability interconnector_9_import_availability interconnector_9_price
          network_gas_export network_gas_import river
          weather/agriculture_heating weather/air_temperature weather/buildings_heating
          weather/insulation_apartments_high weather/insulation_apartments_low weather/insulation_apartments_medium
          weather/insulation_corner_houses_high weather/insulation_corner_houses_low weather/insulation_corner_houses_medium
          weather/insulation_detached_houses_high weather/insulation_detached_houses_low weather/insulation_detached_houses_medium
          weather/insulation_semi_detached_houses_high weather/insulation_semi_detached_houses_low weather/insulation_semi_detached_houses_medium
          weather/insulation_terraced_houses_high weather/insulation_terraced_houses_low weather/insulation_terraced_houses_medium
          weather/solar_pv_profile_1 weather/solar_thermal
          weather/wind_coastal_baseline weather/wind_inland_baseline weather/wind_offshore_baseline
        ]
        end

        def curve_contents
          # Contents for a flat curve
          ("3.170979198376513e-08\n" * 8760).chop # remove last newline
        end
      end # /self
    end # /class Curve
  end # /class Utils
end # /class Benchmarks
