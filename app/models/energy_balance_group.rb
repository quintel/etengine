# == Schema Information
#
# Table name: energy_balance_groups
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class EnergyBalanceGroup < ActiveRecord::Base
  has_many :converters
  
  validates :name, :presence => true
end
