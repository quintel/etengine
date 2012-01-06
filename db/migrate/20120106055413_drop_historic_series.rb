class DropHistoricSeries < ActiveRecord::Migration
  def self.up
    drop_table :historic_serie_entries
    drop_table :historic_series
    drop_table :year_values
  end

  def self.down
  end
end
