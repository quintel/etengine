class MakePolicyGoalGqueriesNotCacheable < ActiveRecord::Migration
  def self.up
    Gquery.where("`key` LIKE 'policy_goal_%'").each do |gquery|
      say "Setting #{gquery.id} #{gquery.key} to not_cacheable"
      gquery.update_attribute :not_cacheable, true
    end
  end

  def self.down
  end
end
