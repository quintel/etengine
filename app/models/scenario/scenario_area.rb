# Area related methods for scenario
#
class Scenario < ActiveRecord::Base

  attr_writer :area


  ##
  # @tested 2010-11-30 seb
  # 
  def set_country_and_region(country, region)
    self.country = country
    self.region = if region.blank? then nil
      elsif region.is_a?(Hash) 
        if region.has_key?(country) 
          region[country]  # You may want to set the province here and override country settings (maybe add a country prefix?)
        else 
          nil
        end
      else region
    end
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def region_or_country
    region.present? ? region : country
  end

  ##
  # @tested 2010-11-30 seb
  # 
  def area
    @area ||= Area.find_by_country(region_or_country)
  end

end