class MigrateCarrierInputs < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'cost_per_mj_growth_total', :update_type => 'carriers').each do |input|
      unless input.keys.blank?
        keys = input.keys.gsub("_AND_", ',')
        query = "UPDATE(CARRIER(#{keys}), cost_per_mj, USER_INPUT())"

        input.v1_legacy_unit = '%'
        input.query = query
        input.save!
      end
    end
  end

  def self.down
    Input.where(:attr_name => 'cost_per_mj_growth_total', :update_type => 'carriers').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
