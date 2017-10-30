class RenameNl2015ToNl < ActiveRecord::Migration
  def up
    Scenario.where(area_code: 'nl2015').find_each do |scenario|
      scenario.area_code = 'nl'
      scenario.save(validate: false)
    end
  end

  def down
    ActiveRecord::IrreversibleMigration
  end
end
