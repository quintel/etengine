class UpdateCapacityFactorInputs < ActiveRecord::Migration
  def self.up
    items = /capacity_factor/
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
    a = s.gsub(/capacity_factor\)\)/, "full_load_seconds))").
      gsub(/DIVIDE\(DIVIDE\(Q\(final_demand_electricity\),Q\(seconds_per_year\)\),/, "DIVIDE(Q(final_demand_electricity),")
    if a != s
      puts "Before: #{s}"
      puts "After: #{a}"
    end
    a
  end  

end
