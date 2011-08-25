class MigrateLinkShareInputs < ActiveRecord::Migration

  def self.up
    Input.where("attr_name LIKE '%link_share'").each do |input|
      keys = input.keys
      attr_name = input.attr_name

      inout = attr_name.include?('input') ? 'INPUT' : 'OUTPUT'
      carrier = attr_name.split("_output_").first

      input_value = "DIVIDE(USER_INPUT(),V(#{input.factor}))"

      query = "UPDATE(FIRST(LINKS(#{inout}_SLOTS(V(#{keys});#{carrier}))), share, #{input_value})"

      say query

      #input.v1_legacy_unit = '%'
      input.query = query
      input.save!
    end

    Input.where("attr_name LIKE 'useable_heat_output_link_share'").each do |input|
      keys = input.keys
      attr_name = input.attr_name

      inout = 'OUTPUT'
      carrier = 'useable_heat'

      input_value = "DIVIDE(USER_INPUT(),V(#{input.factor}))"

      reverse_converter_key = keys.gsub('heat_', 'cold_')

      query = "EACH(
        UPDATE(FIRST(LINKS(#{inout}_SLOTS(V(#{keys});#{carrier}))), share, #{input_value}),
        UPDATE(FIRST(LINKS(#{inout}_SLOTS(V(#{reverse_converter_key});cooling))), share, #{input_value})
      )"
      say query

      #input.v1_legacy_unit = '%'
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where("attr_name LIKE '%link_share'").each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
