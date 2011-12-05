# == Schema Information
#
# Table name: energy_balance_groups
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  graphviz_color     :string(255)
#  graphviz_default_x :integer(4)
#

class EnergyBalanceGroup < ActiveRecord::Base
  has_many :converters, :dependent => :nullify
  
  validates :name, :presence => true
end
