class Area < ActiveRecord::Base
  scope :country, lambda{|c| where(:country => c)}  
  
  def self.get(area_code)
    attributes = Etsource::Loader.instance.area_attributes(area_code)
    attributes.with_indifferent_access
  end
  
end