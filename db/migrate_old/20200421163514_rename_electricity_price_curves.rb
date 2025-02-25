class RenameElectricityPriceCurves < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      UPDATE active_storage_attachments
      SET name = "interconnector_1_price_curve"
      WHERE name = "imported_electricity_price_curve"
    SQL
  end

  def down
    execute <<-SQL
      UPDATE active_storage_attachments
      SET name = "imported_electricity_price_curve"
      WHERE name = "interconnector_1_price_curve"
    SQL
  end
end
