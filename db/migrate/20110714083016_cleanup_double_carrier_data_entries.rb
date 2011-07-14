class CleanupDoubleCarrierDataEntries < ActiveRecord::Migration
  def self.up
    execute "DELETE FROM dataset_carrier_data WHERE id IN (36002,36043,36041,36000,34595,36036,35994,36035,35989,34601,34610,35980)"
  end

  def self.down
    execute "INSERT INTO `dataset_carrier_data` (`id`, `created_at`, `updated_at`, `carrier_id`, `cost_per_mj`, `co2_conversion_per_mj`, `sustainable`, `typical_production_per_km2`, `area_id`, `kg_per_liter`, `mj_per_kg`, `co2_exploration_per_mj`, `co2_extraction_per_mj`, `co2_treatment_per_mj`, `co2_transportation_per_mj`, `co2_waste_treatment_per_mj`, `supply_chain_margin_per_mj`, `oil_price_correlated_part_production_costs`)
    VALUES
    	(36002, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 11, 0.00809576, 0, 1, 2.64e+07, 1, NULL, 16.5, 0, 0, 0, 0, 0, 0, 0),
    	(36043, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 11, 0.00809576, 0, 1, 2.64e+07, 1, NULL, 16.5, 0, 0, 0, 0, 0, 0, 0),
    	(36041, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 13, 0.0215094, 0, 1, 1.25652e+07, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(36000, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 13, 0.0215094, 0, 1, 1.25652e+07, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(34595, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 18, 0.0206464, 0, 1, 5.71429e+06, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(36036, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 18, 0.0206464, 0, 1, 5.71429e+06, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(35994, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 19, 0.0280915, 0, 1, 9.3633e+06, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(36035, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 19, 0.0280915, 0, 1, 9.3633e+06, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(35989, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 24, 0.00770545, NULL, 1, 2.64e+07, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(34601, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 24, 0.00770545, NULL, 1, 2.64e+07, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(34610, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 33, 0.123375, NULL, 1, 3e+06, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0),
    	(35980, '2010-12-16 15:19:06', '2010-12-22 16:17:53', 33, 0.123375, NULL, 1, 3e+06, 1, NULL, NULL, 0, 0, 0, 0, 0, 0, 0);"
  end
end
