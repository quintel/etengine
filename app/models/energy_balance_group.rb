class EnergyBalanceGroup < ActiveRecord::Base
  has_many :converters
  
  validates :name, :presence => true
end
