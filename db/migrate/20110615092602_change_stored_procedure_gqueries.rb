class ChangeStoredProcedureGqueries < ActiveRecord::Migration
  def self.up
    Gquery.where("query LIKE 'stored.%'").each do |gquery|
      gquery.update_attribute :query, gquery.query.gsub('.', ':')
    end
  end

  def self.down
    Gquery.where("query LIKE 'stored:%").each do |gquery|
      gquery.update_attribute :query, gquery.query.gsub(':', '.')
    end
  end
end
