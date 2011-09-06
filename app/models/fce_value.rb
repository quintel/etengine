# == Schema Information
#
# Table name: fce_values
#
#  id                         :integer(4)      not null, primary key
#  using_country              :string(255)
#  origin_country             :string(255)
#  co2_exploration_per_mj     :float
#  co2_extraction_per_mj      :float
#  co2_treatment_per_mj       :float
#  co2_transportation_per_mj  :float
#  co2_conversion_per_mj      :float
#  co2_waste_treatment_per_mj :float
#  created_at                 :datetime
#  updated_at                 :datetime
#  carrier                    :string(255)
#

class FceValue < ActiveRecord::Base

  def self.values(carrier, origin_country, using_country)
    where(
      :carrier => carrier,
      :origin_country => origin_country,
      :using_country => using_country
    ).first
  end

end
