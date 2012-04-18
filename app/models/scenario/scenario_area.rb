# Area related methods for scenario
#
class Scenario < ActiveRecord::Base
  attr_writer :area

  def area
    @area ||= Area.find_by_country(area_code)
  end
end
