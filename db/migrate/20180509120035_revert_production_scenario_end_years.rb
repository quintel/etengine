class RevertProductionScenarioEndYears < ActiveRecord::Migration[5.1]
  SCENARIOS_CSV = <<-CSV
    361011,2050
    361017,2050
    361024,2050
    361033,2050
    361038,2050
    361039,2050
    361040,2050
    361042,2050
    361043,2050
    361053,2050
    361061,2050
    361065,2050
    361066,2050
    361321,2050
    362538,2050
    362539,2050
    362548,2050
    362554,2050
    362560,2050
    362561,2050
    362698,2050
    362701,2050
    362702,2050
    362703,2050
    362705,2050
    362708,2050
    362710,2050
    362712,2050
    362719,2050
    362722,2050
    362724,2050
    362774,2050
    362775,2050
    362776,2050
    362778,2050
    362779,2050
    362782,2050
    362784,2050
    362786,2050
    362789,2050
    362796,2050
    362797,2050
    362800,2050
    362813,2050
    362821,2050
    362822,2050
    362826,2050
    362827,2050
    362828,2050
    362833,2050
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
