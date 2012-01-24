class RenameLandUseConverterColumn < ActiveRecord::Migration
  def self.up
    rename_column :dataset_converter_data, :land_use_in_nl, :land_use_per_unit
    replace_gquery_string(/land_use_in_nl/, "land_use_per_unit")
    
    
  end

  def self.down
    rename_column :dataset_converter_data, :land_use_per_unit, :land_use_in_nl
    replace_gquery_string(/land_use_per_unit/, "land_use_in_nl")    
  end
  
  def self.replace_gquery_string(old, replacement)
    Gquery.find_each do |q|
      if q.query =~ old
        puts "GQuery: ##{q.id}"
        puts "===================="
        puts "Was: #{q.query}"
        puts ">>>"
        new_string = q.query.gsub(old, replacement)
        q.query = new_string
        q.save
        puts new_string
        puts
        puts
      end
    end    
  end
end
