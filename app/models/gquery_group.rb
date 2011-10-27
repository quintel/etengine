# == Schema Information
#
# Table name: gquery_groups
#
#  id          :integer(4)      not null, primary key
#  group_key   :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  description :text
#

class GqueryGroup < ActiveRecord::Base
  has_many :gqueries, :dependent => :nullify
end
