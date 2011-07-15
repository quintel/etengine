class UpdateCarrierCo2Emissions < ActiveRecord::Migration
  def self.up
    execute "UPDATE  `dataset_carrier_data` SET `co2_conversion_per_mj` = 0.055279,    `co2_exploration_per_mj` = 0 , `co2_extraction_per_mj` = 0,         `co2_treatment_per_mj` = 0.00100833,  `co2_transportation_per_mj`=0.0006513,  `co2_waste_treatment_per_mj` = 0 WHERE id = 34586;"
    execute "UPDATE  `dataset_carrier_data` SET `co2_conversion_per_mj` = 2.86484e-05, `co2_exploration_per_mj` = 0 , `co2_extraction_per_mj` = 0.00114704,`co2_treatment_per_mj` = 0.00100833,  `co2_transportation_per_mj`=0.0080812,  `co2_waste_treatment_per_mj` = 0 WHERE id = 34588;"
    execute "UPDATE  `dataset_carrier_data` SET `co2_conversion_per_mj` = 0,           `co2_exploration_per_mj` = 0 , `co2_extraction_per_mj` = 0.0178266, `co2_treatment_per_mj` = 0.00166162,  `co2_transportation_per_mj`=0,          `co2_waste_treatment_per_mj` = 0 WHERE id = 34586;"
    execute "UPDATE  `dataset_carrier_data` SET `co2_conversion_per_mj` = 0.0926835,   `co2_exploration_per_mj` = 0 , `co2_extraction_per_mj` = 0.00383656,`co2_treatment_per_mj` = 0.000739767, `co2_transportation_per_mj`=0.000373771,`co2_waste_treatment_per_mj` = 0 WHERE id = 34586;"
    execute "UPDATE  `dataset_carrier_data` SET `co2_conversion_per_mj` = 0,           `co2_exploration_per_mj` = 0 , `co2_extraction_per_mj` = 4.58e-06,  `co2_treatment_per_mj` = 0.000154245, `co2_transportation_per_mj`=3.486e-06,  `co2_waste_treatment_per_mj` = 0 WHERE id = 34586;"
  end

  def self.down
  end
end
