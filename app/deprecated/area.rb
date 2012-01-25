class Area < ActiveRecord::Base
  scope :country, lambda{|c| where(:country => c)}
end