# When you burn coal, CO2 and other greenhouse gasses are emitted. However, when 
# the coal is dug up from the earth (also called 'Gaia' or 'Mother Earth' btw), 
# then also some gasses get emitted. During transport, gasses are also emitted. 
# We wanna take these emissions into account as well in the model. This is especially 
# relevant in the discussion about nuclear energy. Some experts claim that nuclear 
# energy emits a lot of CO2 while it's begin dug up, transported and processed.
# 
# These emissions vary per type of carrier (obviously), but also per source of 
# carrier. E.g. coal dug up in China emit more than coal dug up in South Africa.
#
# The fuel chain steps are:
# - Exploration
# - Extraction
# - Treatment
# - Transportation
# - Conversion ( That's what we normally do in the model!)
# - Waste treatment 
#
#
# == Use
#
# E.g. 
#
# {
#  "coal"=>
#    {
#     "co2_extraction_per_mj_value"=>0.01440865716,
#     "co2_transportation_per_mj_value"=>0.00022026431999999999, 
#     "co2_conversion_per_mj_value"=>0.10462466859999998, 
#     "co2_exploration_per_mj_value"=>0.0, 
#     "co2_treatment_per_mj_value"=>0.0018691389799999998, 
#     "co2_waste_treatment_per_mj_value"=>0.0
#   }
#  "natural_gas"  => 
#     {
#     ...
#     ...
#     }
# }
#
#
class Scenario < ActiveRecord::Base


    attr_writer :fce_settings

    ##
    # The fce_settings hash stores the co2_emission values per country
    # This hash is updated using the Gql::UpdateInterface::FceCommand
    def fce_settings
      @fce_settings ||= {}
    end

    def update_statements_for_fce
      hsh = {"carriers" => {}}
      fce_settings["carriers"].each do |carrier_key, updates|
        updates.each do |carrier_attr,values|
          hsh["carriers"][carrier_key.to_s] = {} if hsh["carriers"][carrier_key.to_s].nil?
          hsh["carriers"][carrier_key.to_s]["#{carrier_attr}_value"] = values.map(&:last).sum
        end
      end
      hsh
    end
end