class MigrateProductionInMw < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'production_in_mw').each do |input|
      unless input.keys.blank?
        query = "UPDATE(OUTPUT_LINKS(#{input.keys};constant), share, PRODUCT(V(#{input.keys}), USER_INPUT(), SECS_PER_YEAR))"

        #input.v1_legacy_unit = '%y'
        input.query = query
        input.save!
      end
    end
  end

  def self.down
    Input.where(:attr_name => 'decrease_rate').each do |input|
      input.v1_legacy_unit = nil
      input.update_attribute :query, nil
    end
  end
end
