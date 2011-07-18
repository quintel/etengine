class FceValue < ActiveRecord::Base

  def self.values(carrier,origin_country,using_country)
    where(:carrier=>carrier,:origin_country=>origin_country, :using_country => using_country).first
  end

end
