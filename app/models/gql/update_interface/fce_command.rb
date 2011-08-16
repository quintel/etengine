module Gql::UpdateInterface

class FceCommand < CommandBase
  MATCHER = /^(.*)_(fce)$/

  def self.create(carrier, key, value)
    @carrier = carrier
    @key = key
    @value = value
    generate_fce_settings
  end

private

  def self.generate_fce_settings
    origin_country = @key.match(MATCHER).andand.captures.first
    
    # Get the emission values for the carrier where the origin_country is 
    # defined by the slider and the using country is the current country 
    fce_values = FceValue.values(@carrier,origin_country,Current.scenario.country)

    # The co2_emission attributes are calculated in this hash and stored by country
    # E.g. Coal from Russia has a share (@value) of 0.2. Then all the emission attributes are 0.2 * the value found in FceValue
    hsh = 
    {'carriers' => 
      {
        @carrier.to_s => {
          :co2_extraction_per_mj => {
            origin_country => (fce_values.send(:co2_extraction_per_mj) * @value)
          },      
          :co2_transportation_per_mj => {
            origin_country => (fce_values.send(:co2_transportation_per_mj) * @value)
          },
          :co2_conversion_per_mj => {
            origin_country => (fce_values.send(:co2_conversion_per_mj) * @value)
          },
          :co2_exploration_per_mj => {
            origin_country => (fce_values.send(:co2_exploration_per_mj) * @value)
          },
          :co2_treatment_per_mj => {
            origin_country => (fce_values.send(:co2_treatment_per_mj) * @value)
          },
          :co2_waste_treatment_per_mj => {
            origin_country => (fce_values.send(:co2_waste_treatment_per_mj) * @value)
          }
        }
      }
    }
    # When the part of the hash of this carrier is finished merge it into the existing one
    Current.scenario.fce_settings = Current.scenario.fce_settings.deep_merge(hsh)
    
    # return the summed values back to the update statement (summed values is the weighted average)
    # update_statements_for_fce can be found in fce_setting.rb
    Current.scenario.update_statements_for_fce
  end
end

end