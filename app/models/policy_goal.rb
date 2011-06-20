# == Schema Information
#
# Table name: policy_goals
#
#  id                :integer(4)      not null, primary key
#  key               :string(255)
#  name              :string(255)
#  query             :string(255)
#  start_value_query :string(255)
#  unit              :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  display_format    :string(255)
#  reached_query     :string(255)
#

class PolicyGoal < ActiveRecord::Base

  has_one :area_dependency, :as => :dependable
  has_and_belongs_to_many :root_nodes
  belongs_to :round
  has_paper_trail

  def self.allowed_policies
    # DEBT this is the concern of etmodel
    PolicyGoal.all
  end

  def to_gql
    Gql::PolicyGoal.new({
      :id                => id, 
      :key               => key, 
      :name              => name, 
      :query             => query,
      :display_format    => display_format, 
      :unit              => unit, 
      :start_value_query => start_value_query,
      :reached_query     =>  reached_query})
  end
end
