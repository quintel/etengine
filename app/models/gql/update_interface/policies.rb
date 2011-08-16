module Gql
#
# == GQL Update of future graph
#
# All update statements are in a hash retrieved from Current.scenario.update_statements
#
# {'converters' => {
#     'gas_demand_industry_energetic' => {'growth_rate' => '0.01'} }
#   },
# 'carriers' => {
#     'electricity' => {
#       'cost_per_mj_growth_rate' => '0.01'
#     }
# }}
#
#
# == Updating Area data attributes
#
# Updateable attributes defined in Qernel::Area::ATTRIBUTES_USED
#
# {country_key => {'attribute_name_(value|growth)' => 'new_value'} }
#
# e.g.
# { 'nl' => {
#     'co2_price_growth_rate' => '0.01'
#     'co2_price_value' => '300.0'
# }}
#
#
# == Updating carrier attributes:
#
# {id_or_key => {'attribute_name_(value|growth)' => 'new_value'} }
#
# e.g.
# { 'electricity' => {
#     'cost_per_mj_growth_rate' => '0.01'
#     'co2_per_mj_value' => '300.0'
# }}
#
#
# == Converter attributes:
#
# preset demand: 'growth_rate' ('growth_year' is deprecated)
# e.g.
# { 'gas_demand_industry_energetic' => {'growth_rate' => '0.01'} }
#
#
# all attributes defined in Qernel::Calculator::ATTRIBUTES_USED
# {'key' => {'attribute_name_(growth_rate|value)' => 'value'}}
#
# e.g.
# {'key' => {
#    'co2_free_growth_rate' => 'value',
#    'construction_time_value' => 'value
#  }}
#
#
# == Converter Link shares:
#
# Needs a *_market_share method to define flexible links.
#
# {'key' => {'lighting_market_share' => 'value'}}
#
#
# == Converter Efficiency/Slot conversion:
#
# <carrier.key>_input_conversion_growth_rate
# <carrier.key>_output_conversion_growth_rate
#
# {'key' => {'heat_input_conversion_growth_rate' => 'value'}}
#
# == Converter output link share:
#
# If converter has *one* output link for a given carrier:
#
# <carrier.key>_output_link_share
#
# {'key' => {'heat_output_link_share' => 'new_share'}}
#
#
#
class UpdateInterface::Policies

  def initialize(policy)
    @policy = policy
  end

  # Update policies
  #
  def update_with(update_statements)
    if update_statements && update_statements.has_key?('policies')
      update_statements['policies'].andand.each do |id, updates|
        # all policy related inputs have attr_name = value
        @policy.goal(id).user_value = updates['value'] if @policy.goal(id)
      end
    end
  end


end

end
