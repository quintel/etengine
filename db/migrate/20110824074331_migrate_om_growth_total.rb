class MigrateOmGrowthTotal < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'om_growth_total').each do |input|
      keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')

      query = "EACH(
        UPDATE(V(#{keys}), operation_and_maintenance_cost_fixed_per_mw_input, USER_INPUT()),
        UPDATE(V(#{keys}), operation_and_maintenance_cost_variable_per_full_load_hour, USER_INPUT()),
      )"

      input.v1_legacy_unit = '%'
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where(:attr_name => 'om_growth_total').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
