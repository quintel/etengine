class RenamePolicyQuery < ActiveRecord::Migration
  def self.up
    begin
      Gquery.contains('stored.policy_co2_emission').first.update_attribute :query, 'stored:policy_co2_emission' 
    rescue 
      say 'not found'
    end
  end

  def self.down
  end
end
