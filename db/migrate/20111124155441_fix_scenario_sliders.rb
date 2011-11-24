class FixScenarioSliders < ActiveRecord::Migration
  def self.up
    Scenario.where("in_start_menu IS NULL AND id != 17515").each do |s|
      begin
        puts "updating ##{s.id}"
        s.update_hh_inputs!
      rescue
        puts "Error updating ##{s.id}"
        next
      end
    end
  end

  def self.down
  end
end
