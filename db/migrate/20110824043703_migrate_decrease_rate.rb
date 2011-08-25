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
      query = if input.factor != 100
        "UPDATE(V(#{keys}), preset_demand, NEG(DIVIDE(USER_INPUT(),V(#{input.factor/100}))))"
      else
        "UPDATE(V(#{keys}), preset_demand, NEG(USER_INPUT()))"
      end

      input.v1_legacy_unit = '%'
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where(:attr_name => 'decrease_rate').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save!
    end

    Input.where(:attr_name => 'decrease_total').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save!
    end
  end
end
