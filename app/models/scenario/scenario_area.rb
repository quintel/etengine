# Area related methods for scenario
#
class Scenario < ActiveRecord::Base
  def area_input_values
    area = Area.get(area_code)
    hash = area[:input_values]
    if hash.present?
      YAML::load(hash)
    else
      {}
    end
  end
end
