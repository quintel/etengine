# Area related methods for scenario
#
class Scenario < ActiveRecord::Base
  def area_input_values
    area = Area.get(area_code)
    binding.pry
    hash = area[:input_values]
    if hash.present?
      YAML::load(hash)
    else
      nil
    end
  end
end
