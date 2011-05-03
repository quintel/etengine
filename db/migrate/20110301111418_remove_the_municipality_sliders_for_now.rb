class RemoveTheMunicipalitySlidersForNow < ActiveRecord::Migration
  def self.up
    execute "DELETE FROM input_elements WHERE id IN (450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,485,486,487);"
  end

  def self.down
    execute "INSERT INTO `input_elements` (`id`,`name`,`key`,`keys`,`attr_name`,`slide_id`,`share_group`,`start_value_gql`,`min_value_gql`,`max_value_gql`,`min_value`,`max_value`,`start_value`,`order_by`,`step_value`,`created_at`,`updated_at`,`update_type`,`unit`,`factor`,`input_element_type`,`label`,`comments`,`update_value`,`complexity`,`interface_group`,`update_max`,`locked_for_municipalities`,`label_query`)
    VALUES
    	(450, 'Label A', 'demand_households_label_a', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:04', '2011-01-27 15:44:04', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(451, 'Label B', 'demand_households_label_b', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:14', '2011-01-27 15:44:14', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(452, 'Label C', 'demand_households_label_c', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:24', '2011-01-27 15:44:24', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(453, 'Label D', 'demand_households_label_d', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:32', '2011-01-27 15:44:32', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(454, 'Label E', 'demand_households_label_e', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:39', '2011-01-27 15:44:39', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(455, 'Label F', 'demand_households_label_f', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:46', '2011-01-27 15:44:46', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(456, 'Label G', 'demand_households_label_g', '', '', 1, '', NULL, NULL, 'AREA(number_households)', 0, NULL, NULL, NULL, NULL, '2011-01-27 15:44:53', '2011-01-27 15:44:53', '', '#', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(457, 'EPC0', 'demand_buildings_epc0', 'epc_negative_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(458, 'EPC0-05', 'demand_buildings_epc0_05', 'epc_0_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(459, 'EPC05-10', 'demand_buildings_epc05_10', 'epc_05_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(460, 'EPC10-15', 'demand_buildings_epc10_15', 'epc_10_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(461, 'EPC15-20', 'demand_buildings_epc15_20', 'epc_15_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(462, 'EPC20-25', 'demand_buildings_epc20_25', 'epc_20_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(463, 'EPC25', 'demand_buildings_epc25', 'epc_25_buildings', 'demand', 128, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(464, 'Label A', 'demand_buildings_label_a', 'label_a_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:16:31', 'converters', 'm2', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(466, 'Label B', 'demand_buildings_label_b', 'label_b_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:06:35', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(467, 'Label C', 'demand_buildings_label_c', 'label_c_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:06:35', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(468, 'Label D', 'demand_buildings_label_d', 'label_d_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:06:35', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(469, 'Label E', 'demand_buildings_label_e', 'label_e_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:06:35', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(470, 'Label F', 'demand_buildings_label_f', 'label_f_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:06:35', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(471, 'Label G', 'demand_buildings_label_g', 'label_g_buildings', 'demand', 129, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:06:35', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(472, 'EPC0', 'demand_households_epc0', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(473, 'EPC0-02', 'demand_households_epc0_02', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(474, 'EPC02-04', 'demand_households_epc02_04', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(475, 'EPC04-06', 'demand_households_epc04_06', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(476, 'EPC06-08', 'demand_households_epc06_08', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(477, 'EPC08-10', 'demand_households_epc08_10', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:01:45', 'converters', 'm2', 1, 'normal', '', NULL, '', 1, '', '', 0, ''),
    	(478, 'EPC1', 'demand_households_epc1', 'epc_negative_buildings', 'demand', 1, '', NULL, NULL, NULL, 0, 1e+06, 0, NULL, NULL, '2011-01-27 16:01:45', '2011-01-27 16:14:19', 'converters', 'm2', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(479, 'Cars', 'demand_transport_cars', '', '', 24, '', NULL, NULL, NULL, 0, 100, 50, NULL, NULL, '2011-01-27 16:22:03', '2011-01-27 16:22:03', '', '%', 100, 'normal', '', '', '', 1, '', '', 0, ''),
    	(480, 'Public transport', 'demand_transport_public_transport', '', '', 24, '', NULL, NULL, NULL, 0, 100, 25, NULL, NULL, '2011-01-27 16:22:03', '2011-01-27 16:22:03', '', '%', 100, 'normal', '', '', '', 1, '', '', 0, ''),
    	(481, 'Bike', 'demand_transport_bike', '', '', 24, '', NULL, NULL, NULL, 0, 100, 25, NULL, NULL, '2011-01-27 16:22:03', '2011-01-27 16:22:03', '', '%', 100, 'normal', '', '', '', 1, '', '', 0, ''),
    	(482, 'Electricity', 'demand_buildings_electricity_use', 'public_building_electricity_use_buildings', 'demand', 130, '', NULL, NULL, NULL, 0, 1e+06, 0, 2, 1.00, '2011-01-27 16:23:27', '2011-01-27 16:26:56', 'converters', 'GJ', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(483, 'Gas', 'demand_buildings_gas_use', 'public_building_gas_use_buildings', 'demand', 130, '', NULL, NULL, NULL, 0, 1e+06, 0, 2, 1.00, '2011-01-27 16:23:27', '2011-01-27 16:26:39', 'converters', 'GJ', 1, 'normal', '', '', '', 1, '', '', 0, ''),
    	(485, 'Bio fuels', 'demand_transport_bio_fuels', '', '', 24, 'transport_mode', NULL, NULL, NULL, 0, 100, 25, NULL, NULL, '2011-01-27 16:22:03', '2011-01-27 16:22:03', '', '%', 100, 'normal', '', '', '', 1, '', '', 0, ''),
    	(486, 'Electric', 'demand_transport_electric', '', '', 24, 'transport_mode', NULL, NULL, NULL, 0, 100, 25, NULL, NULL, '2011-01-27 16:22:03', '2011-01-27 16:22:03', '', '%', 100, 'normal', '', '', '', 1, '', '', 0, ''),
    	(487, 'Fossil fuels', 'demand_transport_fossil_fuels', '', '', 24, 'transport_mode', NULL, NULL, NULL, 0, 100, 25, NULL, NULL, '2011-01-27 16:22:03', '2011-01-27 16:22:03', '', '%', 100, 'normal', '', '', '', 1, '', '', 0, '');"
  end
end
