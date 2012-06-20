# Area related methods for scenario
#
class Scenario < ActiveRecord::Base
  def area
    Area.get(area_code)
  end

  def area_input_values
    hash = area[:input_values]
    if hash.present?
      YAML::load(hash).with_indifferent_access
    else
      {}
    end
  end
end
