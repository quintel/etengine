class UpdateTypicalCapacity < ActiveRecord::Migration
  def self.up
    Gquery.find_each do |q|
      only = [360, 365,  161, 197, 210, 238, 276, 282, 285]
      next unless only.include?(q.id)
      if q.query =~ /typical_capacity_gross_in_mj_s/
        old = q.query
        n = old.gsub(/typical_capacity_gross_in_mj_s/, "typical_input_capacity_in_mw")
        q.query = n
        q.save
      end
    end
  end

  def self.down
    Gquery.find_each do |q|
      only = [360, 365,  161, 197, 210, 238, 276, 282, 285]
      next unless only.include?(q.id)
      if q.query =~ /typical_input_capacity_in_mw/
        old = q.query
        n = old.gsub(/typical_input_capacity_in_mw/, "typical_capacity_gross_in_mj_s")
        q.query = n
        q.save
      end
    end
  end
end
