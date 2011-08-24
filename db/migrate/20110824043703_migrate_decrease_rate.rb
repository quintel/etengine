class MigrateDecreaseRate < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'decrease_rate').each do |input|
      keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')
      query = "UPDATE(V(#{keys}), preset_demand, NEG(USER_INPUT()))"

      input.v1_legacy_unit = '%y'
      input.query = query
      input.save!
    end

    Input.where(:attr_name => 'decrease_total').each do |input|
      keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')
      query = "UPDATE(V(#{keys}), preset_demand, NEG(USER_INPUT()))"

      input.v1_legacy_unit = '%'
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where(:attr_name => 'decrease_rate').each do |input|
      input.v1_legacy_unit = nil
      input.update_attribute :query, nil
    end

    Input.where(:attr_name => 'decrease_total').each do |input|
      input.v1_legacy_unit = nil
      input.update_attribute :query, nil
    end
  end
end
