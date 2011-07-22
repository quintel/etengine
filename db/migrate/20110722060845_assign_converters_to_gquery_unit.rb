class AssignConvertersToGqueryUnit < ActiveRecord::Migration
  def self.up
    Gquery.all.each do |gquery|
      # puts "#{gquery.id} #{gquery.key}"
      result = Current.gql.query(gquery.query) rescue nil
      if result.respond_to?(:present_value)
        result = result.present_value
      end
      if result.is_a?(Array)
        if result.any?{|r| r.is_a?(Qernel::Converter)} and gquery.unit != 'converters'
          say "Updating: #{gquery.id} #{gquery.key}"
          gquery.update_attribute :unit, 'converters'
        end
      end
    end
  end

  def self.down
  end
end
