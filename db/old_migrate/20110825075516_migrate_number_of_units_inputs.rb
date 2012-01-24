class MigrateNumberOfUnitsInputs < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'number_of_units').each do |input|
      if !input.keys.blank?
        keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')

        query = "EACH(
            UPDATE(V(#{keys}), number_of_units, USER_INPUT()),
            UPDATE(OUTPUT_LINKS(V(#{keys});constant), share, V(#{keys}; production_based_on_number_of_units)),
          )"

        input.query = query
        input.save!
      end
    end
  end

  def self.down
    Input.where(:attr_name => 'number_of_units').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
