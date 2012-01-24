class DeleteOldGraphs < ActiveRecord::Migration
  def self.up
    Graph.where("created_at < '2011-03-01'").each do |graph|
      graph.destroy
    end
    Blueprint.where("created_at < '2011-03-01'").each do |blueprint|
      blueprint.destroy
    end
  end

  def self.down
  end
end
