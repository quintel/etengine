class FixGqueris < ActiveRecord::Migration
  def self.up
    Gquery.find(1424).andand.destroy
    Gquery.find(1425).andand.destroy
    Gquery.find(1452).andand.destroy
    Gquery.find(336).andand.update_attribute :unit, 'converters'
  end

  def self.down
  end
end


# gqs = Gquery.all; nil
# gqs.reject{|g| g.unit == 'converters'}.each do |gq|
#   puts "#{gq.id} #{gq.key}"
#   puts "   "+[Current.gql.query(gq.query)].flatten.join("\t")
# end; nil