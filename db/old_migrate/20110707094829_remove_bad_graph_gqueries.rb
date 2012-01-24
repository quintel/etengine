class RemoveBadGraphGqueries < ActiveRecord::Migration
  def self.up
    Gquery.destroy_all("id >= 680 AND id <= 1025")
  end

  def self.down
  end
end
