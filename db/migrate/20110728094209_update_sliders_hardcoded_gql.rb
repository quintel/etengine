class UpdateSlidersHardcodedGql < ActiveRecord::Migration
  def self.up
    items = /typical_production|typical_capacity_gross_in_mj_s|land_use_in_nl|technical_lifetime/
    fields = [:start_value_gql, :min_value_gql, :max_value_gql]
    Input.find_each do |q|
      if fields.any?{|x| q.send(x) =~ items}
        x = {
          :id    => q.id, 
          :start => q.start_value_gql, 
          :min   => q.min_value_gql, 
          :max   => q.max_value_gql
        }
        puts x.to_yaml
        puts
        
        fields.each do |f|
          q.send("#{f}=", self.replace_string(q.send(f)))
        end
        puts "Saving record"
        q.save
      end        
    end
  end

  def self.down
  end
  
  def self.replace_string(s)
    return unless s
    a = s.gsub(/typical_production/, "typical_electricity_production_per_unit").
      gsub(/typical_capacity_gross_in_mj_s/, "typical_electricity_production_capacity").
      gsub(/land_use_in_nl/, "land_use_per_unit").
      gsub(/technical_lifetime/, "economical_lifetime")
    if a != s
      puts "Before: #{s}"
      puts "After: #{a}"
    end
    a
  end  
end
