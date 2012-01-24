class MigrateConversionInputs < ActiveRecord::Migration
  def self.up
    Input.where("attr_name LIKE '%_conversion_%'").each do |input|
      keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')
      attr_name = input.attr_name

      carrier_inout, update_type = attr_name.split('_conversion_')
      carrier_inout = carrier_inout.split("_")

      inout = carrier_inout.pop.upcase
      carrier = carrier_inout.join('_')

      if update_type == 'conversion'
        query = "UPDATE( #{inout}_SLOTS(V(#{keys});#{carrier}), conversion, DIVIDE(USER_INPUT(),100))"
      else
        query = "UPDATE( #{inout}_SLOTS(V(#{keys});#{carrier}), conversion, USER_INPUT())"
        input.v1_legacy_unit = '%y'
      end
      say query
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where("attr_name LIKE '%_conversion_%'").each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
