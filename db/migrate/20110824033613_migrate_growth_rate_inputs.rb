class MigrateGrowthRateInputs < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'growth_rate').each do |input|
      keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')
      query = "UPDATE(V(#{keys}), preset_demand, USER_INPUT())"

      input.v1_legacy_unit = '%y'
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where(:attr_name => 'growth_rate').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
