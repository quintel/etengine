class UpdateProductionScenarioEndYears < ActiveRecord::Migration[5.1]
  SCENARIOS_CSV = <<-CSV
    361321,2030
    362538,2030
    362539,2030
    361061,2030
    361065,2030
    361066,2030
    361053,2030
    362548,2030
    362560,2050
    362554,2050
    362701,2040
    362561,2050
    362702,2040
    362703,2050
    362705,2050
    362708,2050
    362710,2050
    362712,2045
    362719,2050
    362722,2040
    362724,2040
    362774,2050
    362775,2050
    362776,2040
    362778,2040
    362779,2030
    362782,2030
    362784,2030
    362786,2030
    362789,2030
    362796,2030
    362797,2030
    362800,2050
    362813,2050
    362821,2035
    362822,2050
    362826,2050
    362827,2050
    362828,2035
    362833,2040
    362698,2050
    361038,2040
    361011,2030
    361017,2030
    361024,2050
    361033,2050
    361039,2030
    361040,2050
    361042,2050
    361043,2050
  CSV

  def change
    return unless Rails.env.production?

    reversible do |dir|
      dir.up do
        SCENARIOS_CSV.each_line do |line|
          id, year = line.strip.split(',')

          Scenario.find(id).update_attributes!(end_year: year)
        end
      end

      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end
    end
  end
end
