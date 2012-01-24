CREATE TABLE `areas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `co2_price` float DEFAULT NULL,
  `co2_percentage_free` float DEFAULT NULL,
  `el_import_capacity` float DEFAULT NULL,
  `el_export_capacity` float DEFAULT NULL,
  `co2_emission_1990` float DEFAULT NULL,
  `co2_emission_2009` float DEFAULT NULL,
  `co2_emission_electricity_1990` float DEFAULT NULL,
  `roof_surface_available_pv` float DEFAULT NULL,
  `coast_line` float DEFAULT NULL,
  `offshore_suitable_for_wind` float DEFAULT NULL,
  `onshore_suitable_for_wind` float DEFAULT NULL,
  `areable_land` float DEFAULT NULL,
  `available_land` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `land_available_for_solar` float DEFAULT NULL,
  `km_per_car` float DEFAULT NULL,
  `import_electricity_primary_demand_factor` float DEFAULT '1.82',
  `export_electricity_primary_demand_factor` float DEFAULT '1',
  `capacity_buffer_in_mj_s` float DEFAULT NULL,
  `capacity_buffer_decentral_in_mj_s` float DEFAULT NULL,
  `km_per_truck` float DEFAULT NULL,
  `annual_infrastructure_cost_electricity` float DEFAULT NULL,
  `number_households` float DEFAULT NULL,
  `number_inhabitants` float DEFAULT NULL,
  `use_network_calculations` tinyint(1) DEFAULT NULL,
  `has_coastline` tinyint(1) DEFAULT NULL,
  `has_mountains` tinyint(1) DEFAULT NULL,
  `has_lignite` tinyint(1) DEFAULT NULL,
  `annual_infrastructure_cost_gas` float DEFAULT NULL,
  `entity` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `percentage_of_new_houses` float DEFAULT NULL,
  `recirculation` float DEFAULT NULL,
  `heat_recovery` float DEFAULT NULL,
  `ventilation_rate` float DEFAULT NULL,
  `market_share_daylight_control` float DEFAULT NULL,
  `market_share_motion_detection` float DEFAULT NULL,
  `buildings_heating_share_offices` float DEFAULT NULL,
  `buildings_heating_share_schools` float DEFAULT NULL,
  `buildings_heating_share_other` float DEFAULT NULL,
  `roof_surface_available_pv_buildings` float DEFAULT NULL,
  `insulation_level_existing_houses` float DEFAULT NULL,
  `insulation_level_new_houses` float DEFAULT NULL,
  `insulation_level_schools` float DEFAULT NULL,
  `insulation_level_offices` float DEFAULT NULL,
  `has_buildings` tinyint(1) DEFAULT NULL,
  `has_agriculture` tinyint(1) DEFAULT '1',
  `current_electricity_demand_in_mj` bigint(20) DEFAULT '1',
  `has_solar_csp` tinyint(1) DEFAULT NULL,
  `has_old_technologies` tinyint(1) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `has_cold_network` tinyint(1) DEFAULT NULL,
  `cold_network_potential` float DEFAULT NULL,
  `has_heat_import` tinyint(1) DEFAULT NULL,
  `has_industry` tinyint(1) DEFAULT NULL,
  `has_other` tinyint(1) DEFAULT NULL,
  `has_fce` tinyint(1) DEFAULT NULL,
  `input_values` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `index_areas_on_parent_id` (`parent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `blueprint_layouts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

CREATE TABLE `blueprint_models` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `blueprints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `graph_version` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `blueprint_model_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_blueprints_on_blueprint_model_id` (`blueprint_model_id`)
) ENGINE=InnoDB AUTO_INCREMENT=954 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `blueprints_converters` (
  `converter_id` int(11) DEFAULT NULL,
  `blueprint_id` int(11) DEFAULT NULL,
  KEY `index_blueprints_converters_on_blueprint_id` (`blueprint_id`),
  KEY `index_blueprints_converters_on_converter_id_and_blueprint_id` (`converter_id`,`blueprint_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `carriers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `carrier_id` int(11) DEFAULT NULL,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `infinite` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `carrier_color` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_carriers_on_carrier_id` (`carrier_id`),
  KEY `index_carriers_on_key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `converter_positions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `converter_id` int(11) DEFAULT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `hidden` tinyint(1) DEFAULT NULL,
  `blueprint_layout_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_converter_positions_on_converter_id` (`converter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=556 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `converters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `converter_id` int(11) DEFAULT NULL,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `use_id` int(11) DEFAULT NULL,
  `sector_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `energy_balance_group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=556 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `converters_groups` (
  `converter_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  KEY `index_converters_groups_on_converter_id_and_group_id` (`converter_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `dataset_carrier_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `carrier_id` int(11) DEFAULT NULL,
  `cost_per_mj` float DEFAULT NULL,
  `co2_conversion_per_mj` float DEFAULT NULL,
  `sustainable` float DEFAULT NULL,
  `typical_production_per_km2` float DEFAULT NULL,
  `area_id` int(11) DEFAULT NULL,
  `kg_per_liter` float DEFAULT NULL,
  `mj_per_kg` float DEFAULT NULL,
  `co2_exploration_per_mj` float DEFAULT '0',
  `co2_extraction_per_mj` float DEFAULT '0',
  `co2_treatment_per_mj` float DEFAULT '0',
  `co2_transportation_per_mj` float DEFAULT '0',
  `co2_waste_treatment_per_mj` float DEFAULT '0',
  `supply_chain_margin_per_mj` float DEFAULT NULL,
  `oil_price_correlated_part_production_costs` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dataset_carrier_data_on_carrier_id` (`carrier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=36866 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `dataset_converter_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `preset_demand` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `dataset_id` int(11) DEFAULT NULL,
  `converter_id` int(11) DEFAULT NULL,
  `demand_expected_value` bigint(20) DEFAULT NULL,
  `network_capacity_available_in_mw` float DEFAULT NULL,
  `network_capacity_used_in_mw` float DEFAULT NULL,
  `land_use_per_unit` float DEFAULT NULL,
  `technical_lifetime` float DEFAULT NULL,
  `lead_time` float DEFAULT NULL,
  `construction_time` float DEFAULT NULL,
  `costs_per_mj` float DEFAULT NULL,
  `network_expansion_costs_in_euro_per_mw` float DEFAULT NULL,
  `use_id` int(11) DEFAULT NULL,
  `sector_id` int(11) DEFAULT NULL,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wacc` float DEFAULT NULL,
  `capacity_factor` float DEFAULT NULL,
  `co2_free` float DEFAULT NULL,
  `simult_wd` float DEFAULT NULL,
  `simult_sd` float DEFAULT NULL,
  `simult_we` float DEFAULT NULL,
  `simult_se` float DEFAULT NULL,
  `peak_load_units_present` float DEFAULT NULL,
  `full_load_hours` float DEFAULT NULL,
  `operation_and_maintenance_cost_fixed_per_mw_input` float DEFAULT NULL,
  `operation_and_maintenance_cost_variable_per_full_load_hour` float DEFAULT NULL,
  `municipality_demand` bigint(20) DEFAULT NULL,
  `typical_nominal_input_capacity` float DEFAULT NULL,
  `residual_value_per_mw_input` float DEFAULT NULL,
  `decommissioning_costs_per_mw_input` float DEFAULT NULL,
  `purchase_price_per_mw_input` float DEFAULT NULL,
  `installing_costs_per_mw_input` float DEFAULT NULL,
  `part_ets` float DEFAULT NULL,
  `ccs_investment_per_mw_input` float DEFAULT NULL,
  `ccs_operation_and_maintenance_cost_per_full_load_hour` float DEFAULT NULL,
  `decrease_in_nomimal_capacity_over_lifetime` float DEFAULT NULL,
  `availability` float DEFAULT NULL,
  `variability` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_converter_datas_on_graph_data_id` (`dataset_id`),
  KEY `index_dataset_converter_data_on_converter_id` (`converter_id`)
) ENGINE=InnoDB AUTO_INCREMENT=592002 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `dataset_link_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `link_type` int(11) DEFAULT '0',
  `share` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `dataset_id` int(11) DEFAULT NULL,
  `link_id` int(11) DEFAULT NULL,
  `max_demand` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_link_datas_on_graph_data_id` (`dataset_id`),
  KEY `index_dataset_link_data_on_link_id` (`link_id`)
) ENGINE=InnoDB AUTO_INCREMENT=821271 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `dataset_slot_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dataset_id` int(11) DEFAULT NULL,
  `slot_id` int(11) DEFAULT NULL,
  `conversion` float DEFAULT NULL,
  `dynamic` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_slot_datas_on_graph_data_id` (`dataset_id`),
  KEY `index_dataset_slot_data_on_slot_id` (`slot_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1167984 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `datasets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `blueprint_id` int(11) DEFAULT NULL,
  `region_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `area_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_graph_datas_on_region_code` (`region_code`)
) ENGINE=InnoDB AUTO_INCREMENT=1447 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `energy_balance_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `graphviz_color` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `graphviz_default_x` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE `fce_values` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `using_country` varchar(255) DEFAULT NULL,
  `origin_country` varchar(255) DEFAULT NULL,
  `co2_exploration_per_mj` float DEFAULT NULL,
  `co2_extraction_per_mj` float DEFAULT NULL,
  `co2_treatment_per_mj` float DEFAULT NULL,
  `co2_transportation_per_mj` float DEFAULT NULL,
  `co2_conversion_per_mj` float DEFAULT NULL,
  `co2_waste_treatment_per_mj` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `carrier` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=latin1;

CREATE TABLE `gql_test_cases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `instruction` longtext COLLATE utf8_unicode_ci,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `settings` longtext COLLATE utf8_unicode_ci,
  `inputs` longtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=318 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gqueries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `query` text COLLATE utf8_unicode_ci,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `not_cacheable` tinyint(1) DEFAULT '0',
  `unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `deprecated_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `gquery_group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gqueries_on_key` (`key`),
  KEY `index_gqueries_on_gquery_group_id` (`gquery_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=183298 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `gquery_groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2592 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `graphs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `blueprint_id` int(11) DEFAULT NULL,
  `dataset_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_user_graphs_on_graph_data_id` (`dataset_id`),
  KEY `index_graphs_on_blueprint_id` (`blueprint_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1025 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `shortcut` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_groups_on_group_id` (`group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `input_tool_forms` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `area_code` varchar(255) DEFAULT NULL,
  `code` varchar(255) DEFAULT NULL,
  `values` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE `inputs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `keys` text COLLATE utf8_unicode_ci,
  `attr_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `share_group` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `start_value_gql` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `min_value_gql` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `max_value_gql` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `min_value` float DEFAULT NULL,
  `max_value` float DEFAULT NULL,
  `start_value` float DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `update_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `factor` float DEFAULT NULL,
  `label` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `comments` text COLLATE utf8_unicode_ci,
  `label_query` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `updateable_period` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'future',
  `query` text COLLATE utf8_unicode_ci,
  `v1_legacy_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique api key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=1006 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `blueprint_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `child_id` int(11) DEFAULT NULL,
  `carrier_id` int(11) DEFAULT NULL,
  `link_type` int(11) DEFAULT NULL,
  `country_specific` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_links_on_blueprint_id` (`blueprint_id`),
  KEY `index_links_on_parent_id` (`parent_id`),
  KEY `index_links_on_child_id` (`child_id`),
  KEY `index_links_on_carrier_id` (`carrier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=303717 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `query_table_cells` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `query_table_id` int(11) DEFAULT NULL,
  `row` int(11) DEFAULT NULL,
  `column` int(11) DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `gquery` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_query_table_cells_on_query_table_id` (`query_table_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7851 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `query_tables` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `row_count` int(11) DEFAULT NULL,
  `column_count` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `scenarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `user_updates` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_values` text COLLATE utf8_unicode_ci,
  `end_year` int(11) DEFAULT '2040',
  `country` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `in_start_menu` tinyint(1) DEFAULT NULL,
  `region` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `complexity` int(11) DEFAULT '3',
  `scenario_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `preset_scenario_id` int(11) DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `use_fce` tinyint(1) DEFAULT NULL,
  `present_updated_at` datetime DEFAULT NULL,
  `protected` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20096 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `slots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `blueprint_id` int(11) DEFAULT NULL,
  `converter_id` int(11) DEFAULT NULL,
  `carrier_id` int(11) DEFAULT NULL,
  `direction` int(11) DEFAULT NULL,
  `country_specific` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_slots_on_blueprint_id` (`blueprint_id`),
  KEY `index_slots_on_converter_id` (`converter_id`),
  KEY `index_slots_on_carrier_id` (`carrier_id`)
) ENGINE=InnoDB AUTO_INCREMENT=541221 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `time_curve_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `graph_id` int(11) DEFAULT NULL,
  `converter_id` int(11) DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `value` float DEFAULT NULL,
  `value_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_time_curve_entries_on_graph_id` (`graph_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1553925 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `company_school` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `allow_news` tinyint(1) DEFAULT '1',
  `heared_first_at` varchar(255) COLLATE utf8_unicode_ci DEFAULT '..',
  `crypted_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_salt` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `persistence_token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `perishable_token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `login_count` int(11) NOT NULL DEFAULT '0',
  `failed_login_count` int(11) NOT NULL DEFAULT '0',
  `last_request_at` datetime DEFAULT NULL,
  `current_login_at` datetime DEFAULT NULL,
  `last_login_at` datetime DEFAULT NULL,
  `current_login_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_login_ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `openid_identifier` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone_number` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `group` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `trackable` varchar(255) COLLATE utf8_unicode_ci DEFAULT '0',
  `send_score` tinyint(1) DEFAULT '0',
  `new_round` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_users_on_trackable` (`trackable`)
) ENGINE=InnoDB AUTO_INCREMENT=180 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `item_id` int(11) NOT NULL,
  `event` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `whodunnit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `object` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_versions_on_item_type_and_item_id` (`item_type`,`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18186 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('');

INSERT INTO schema_migrations (version) VALUES ('20100301084818');

INSERT INTO schema_migrations (version) VALUES ('20100301131719');

INSERT INTO schema_migrations (version) VALUES ('20100303124739');

INSERT INTO schema_migrations (version) VALUES ('20100305084810');

INSERT INTO schema_migrations (version) VALUES ('20100305095730');

INSERT INTO schema_migrations (version) VALUES ('20100305152953');

INSERT INTO schema_migrations (version) VALUES ('20100308112318');

INSERT INTO schema_migrations (version) VALUES ('20100308143739');

INSERT INTO schema_migrations (version) VALUES ('20100309144012');

INSERT INTO schema_migrations (version) VALUES ('20100309155401');

INSERT INTO schema_migrations (version) VALUES ('20100310125039');

INSERT INTO schema_migrations (version) VALUES ('20100310125324');

INSERT INTO schema_migrations (version) VALUES ('20100310125503');

INSERT INTO schema_migrations (version) VALUES ('20100310142435');

INSERT INTO schema_migrations (version) VALUES ('20100310144929');

INSERT INTO schema_migrations (version) VALUES ('20100311085541');

INSERT INTO schema_migrations (version) VALUES ('20100311130859');

INSERT INTO schema_migrations (version) VALUES ('20100316093127');

INSERT INTO schema_migrations (version) VALUES ('20100317141227');

INSERT INTO schema_migrations (version) VALUES ('20100322154344');

INSERT INTO schema_migrations (version) VALUES ('20100323130834');

INSERT INTO schema_migrations (version) VALUES ('20100323131515');

INSERT INTO schema_migrations (version) VALUES ('20100323133000');

INSERT INTO schema_migrations (version) VALUES ('20100324093312');

INSERT INTO schema_migrations (version) VALUES ('20100324093342');

INSERT INTO schema_migrations (version) VALUES ('20100325105712');

INSERT INTO schema_migrations (version) VALUES ('20100326101213');

INSERT INTO schema_migrations (version) VALUES ('20100329145040');

INSERT INTO schema_migrations (version) VALUES ('20100330084300');

INSERT INTO schema_migrations (version) VALUES ('20100330092023');

INSERT INTO schema_migrations (version) VALUES ('20100330094627');

INSERT INTO schema_migrations (version) VALUES ('20100330155511');

INSERT INTO schema_migrations (version) VALUES ('20100401084859');

INSERT INTO schema_migrations (version) VALUES ('20100402125614');

INSERT INTO schema_migrations (version) VALUES ('20100402130921');

INSERT INTO schema_migrations (version) VALUES ('20100406132140');

INSERT INTO schema_migrations (version) VALUES ('20100408145714');

INSERT INTO schema_migrations (version) VALUES ('20100409085718');

INSERT INTO schema_migrations (version) VALUES ('20100412102623');

INSERT INTO schema_migrations (version) VALUES ('20100412130839');

INSERT INTO schema_migrations (version) VALUES ('20100414072253');

INSERT INTO schema_migrations (version) VALUES ('20100414072536');

INSERT INTO schema_migrations (version) VALUES ('20100415073446');

INSERT INTO schema_migrations (version) VALUES ('20100415132335');

INSERT INTO schema_migrations (version) VALUES ('20100416081236');

INSERT INTO schema_migrations (version) VALUES ('20100416142827');

INSERT INTO schema_migrations (version) VALUES ('20100419125242');

INSERT INTO schema_migrations (version) VALUES ('20100419135302');

INSERT INTO schema_migrations (version) VALUES ('20100420110739');

INSERT INTO schema_migrations (version) VALUES ('20100421082639');

INSERT INTO schema_migrations (version) VALUES ('20100421125935');

INSERT INTO schema_migrations (version) VALUES ('20100421150255');

INSERT INTO schema_migrations (version) VALUES ('20100421190459');

INSERT INTO schema_migrations (version) VALUES ('20100426121528');

INSERT INTO schema_migrations (version) VALUES ('20100427084239');

INSERT INTO schema_migrations (version) VALUES ('20100427093358');

INSERT INTO schema_migrations (version) VALUES ('20100427104402');

INSERT INTO schema_migrations (version) VALUES ('20100427105453');

INSERT INTO schema_migrations (version) VALUES ('20100428091737');

INSERT INTO schema_migrations (version) VALUES ('20100428152048');

INSERT INTO schema_migrations (version) VALUES ('20100507093356');

INSERT INTO schema_migrations (version) VALUES ('20100507105550');

INSERT INTO schema_migrations (version) VALUES ('20100510083748');

INSERT INTO schema_migrations (version) VALUES ('20100510114224');

INSERT INTO schema_migrations (version) VALUES ('20100514124659');

INSERT INTO schema_migrations (version) VALUES ('20100514125933');

INSERT INTO schema_migrations (version) VALUES ('20100514143356');

INSERT INTO schema_migrations (version) VALUES ('20100517083607');

INSERT INTO schema_migrations (version) VALUES ('20100517084750');

INSERT INTO schema_migrations (version) VALUES ('20100518083049');

INSERT INTO schema_migrations (version) VALUES ('20100518132653');

INSERT INTO schema_migrations (version) VALUES ('20100518135444');

INSERT INTO schema_migrations (version) VALUES ('20100518140514');

INSERT INTO schema_migrations (version) VALUES ('20100518142236');

INSERT INTO schema_migrations (version) VALUES ('20100521121530');

INSERT INTO schema_migrations (version) VALUES ('20100521121547');

INSERT INTO schema_migrations (version) VALUES ('20100521144207');

INSERT INTO schema_migrations (version) VALUES ('20100524151600');

INSERT INTO schema_migrations (version) VALUES ('20100526100248');

INSERT INTO schema_migrations (version) VALUES ('20100526100434');

INSERT INTO schema_migrations (version) VALUES ('20100526113029');

INSERT INTO schema_migrations (version) VALUES ('20100526150446');

INSERT INTO schema_migrations (version) VALUES ('20100528110327');

INSERT INTO schema_migrations (version) VALUES ('20100528131141');

INSERT INTO schema_migrations (version) VALUES ('20100601090601');

INSERT INTO schema_migrations (version) VALUES ('20100602140410');

INSERT INTO schema_migrations (version) VALUES ('20100604082854');

INSERT INTO schema_migrations (version) VALUES ('20100604095124');

INSERT INTO schema_migrations (version) VALUES ('20100604153124');

INSERT INTO schema_migrations (version) VALUES ('20100607161408');

INSERT INTO schema_migrations (version) VALUES ('20100609113907');

INSERT INTO schema_migrations (version) VALUES ('20100610105216');

INSERT INTO schema_migrations (version) VALUES ('20100610125417');

INSERT INTO schema_migrations (version) VALUES ('20100616114317');

INSERT INTO schema_migrations (version) VALUES ('20100616122648');

INSERT INTO schema_migrations (version) VALUES ('20100616150424');

INSERT INTO schema_migrations (version) VALUES ('20100616151553');

INSERT INTO schema_migrations (version) VALUES ('20100617075231');

INSERT INTO schema_migrations (version) VALUES ('20100617084055');

INSERT INTO schema_migrations (version) VALUES ('20100617140128');

INSERT INTO schema_migrations (version) VALUES ('20100617154321');

INSERT INTO schema_migrations (version) VALUES ('20100618122409');

INSERT INTO schema_migrations (version) VALUES ('20100618125022');

INSERT INTO schema_migrations (version) VALUES ('20100622090605');

INSERT INTO schema_migrations (version) VALUES ('20100622133237');

INSERT INTO schema_migrations (version) VALUES ('20100622172220');

INSERT INTO schema_migrations (version) VALUES ('20100629124418');

INSERT INTO schema_migrations (version) VALUES ('20100630082139');

INSERT INTO schema_migrations (version) VALUES ('20100701092118');

INSERT INTO schema_migrations (version) VALUES ('20100701154256');

INSERT INTO schema_migrations (version) VALUES ('20100701165718');

INSERT INTO schema_migrations (version) VALUES ('20100701201143');

INSERT INTO schema_migrations (version) VALUES ('20100705115148');

INSERT INTO schema_migrations (version) VALUES ('20100706104738');

INSERT INTO schema_migrations (version) VALUES ('20100707090601');

INSERT INTO schema_migrations (version) VALUES ('20100708120017');

INSERT INTO schema_migrations (version) VALUES ('20100708120143');

INSERT INTO schema_migrations (version) VALUES ('20100708120259');

INSERT INTO schema_migrations (version) VALUES ('20100709110919');

INSERT INTO schema_migrations (version) VALUES ('20100712111517');

INSERT INTO schema_migrations (version) VALUES ('20100712114454');

INSERT INTO schema_migrations (version) VALUES ('20100712125331');

INSERT INTO schema_migrations (version) VALUES ('20100715121741');

INSERT INTO schema_migrations (version) VALUES ('20100715132526');

INSERT INTO schema_migrations (version) VALUES ('20100716095057');

INSERT INTO schema_migrations (version) VALUES ('20100716115146');

INSERT INTO schema_migrations (version) VALUES ('20100716143136');

INSERT INTO schema_migrations (version) VALUES ('20100716143345');

INSERT INTO schema_migrations (version) VALUES ('20100719142456');

INSERT INTO schema_migrations (version) VALUES ('20100720170743');

INSERT INTO schema_migrations (version) VALUES ('20100721114726');

INSERT INTO schema_migrations (version) VALUES ('20100721131615');

INSERT INTO schema_migrations (version) VALUES ('20100721133542');

INSERT INTO schema_migrations (version) VALUES ('20100722143014');

INSERT INTO schema_migrations (version) VALUES ('20100722154030');

INSERT INTO schema_migrations (version) VALUES ('20100722154122');

INSERT INTO schema_migrations (version) VALUES ('20100722154147');

INSERT INTO schema_migrations (version) VALUES ('20100722154303');

INSERT INTO schema_migrations (version) VALUES ('20100722156000');

INSERT INTO schema_migrations (version) VALUES ('20100722160307');

INSERT INTO schema_migrations (version) VALUES ('20100722160500');

INSERT INTO schema_migrations (version) VALUES ('20100722160958');

INSERT INTO schema_migrations (version) VALUES ('20100726215958');

INSERT INTO schema_migrations (version) VALUES ('20100726225406');

INSERT INTO schema_migrations (version) VALUES ('20100726226400');

INSERT INTO schema_migrations (version) VALUES ('20100726227400');

INSERT INTO schema_migrations (version) VALUES ('20100727105245');

INSERT INTO schema_migrations (version) VALUES ('20100727110317');

INSERT INTO schema_migrations (version) VALUES ('20100727130529');

INSERT INTO schema_migrations (version) VALUES ('20100727164450');

INSERT INTO schema_migrations (version) VALUES ('20100728130546');

INSERT INTO schema_migrations (version) VALUES ('20100728161541');

INSERT INTO schema_migrations (version) VALUES ('20100730161743');

INSERT INTO schema_migrations (version) VALUES ('20100730162600');

INSERT INTO schema_migrations (version) VALUES ('20100804135201');

INSERT INTO schema_migrations (version) VALUES ('20100809134416');

INSERT INTO schema_migrations (version) VALUES ('20100809144242');

INSERT INTO schema_migrations (version) VALUES ('20100819123129');

INSERT INTO schema_migrations (version) VALUES ('20100826084958');

INSERT INTO schema_migrations (version) VALUES ('20100826104923');

INSERT INTO schema_migrations (version) VALUES ('20100826153555');

INSERT INTO schema_migrations (version) VALUES ('20100830100318');

INSERT INTO schema_migrations (version) VALUES ('20100830133504');

INSERT INTO schema_migrations (version) VALUES ('20100831090037');

INSERT INTO schema_migrations (version) VALUES ('20100907133852');

INSERT INTO schema_migrations (version) VALUES ('20100915134336');

INSERT INTO schema_migrations (version) VALUES ('20100916145244');

INSERT INTO schema_migrations (version) VALUES ('20100917124146');

INSERT INTO schema_migrations (version) VALUES ('20100917124150');

INSERT INTO schema_migrations (version) VALUES ('20100920121917');

INSERT INTO schema_migrations (version) VALUES ('20100921150944');

INSERT INTO schema_migrations (version) VALUES ('20101001065511');

INSERT INTO schema_migrations (version) VALUES ('20101018065902');

INSERT INTO schema_migrations (version) VALUES ('20101019112228');

INSERT INTO schema_migrations (version) VALUES ('20101025120525');

INSERT INTO schema_migrations (version) VALUES ('20101025153059');

INSERT INTO schema_migrations (version) VALUES ('20101026113941');

INSERT INTO schema_migrations (version) VALUES ('20101026122329');

INSERT INTO schema_migrations (version) VALUES ('20101101105549');

INSERT INTO schema_migrations (version) VALUES ('20101102163710');

INSERT INTO schema_migrations (version) VALUES ('20101103105049');

INSERT INTO schema_migrations (version) VALUES ('20101109150403');

INSERT INTO schema_migrations (version) VALUES ('20101115113333');

INSERT INTO schema_migrations (version) VALUES ('20101118093028');

INSERT INTO schema_migrations (version) VALUES ('20101126100724');

INSERT INTO schema_migrations (version) VALUES ('20101129120818');

INSERT INTO schema_migrations (version) VALUES ('20101129135600');

INSERT INTO schema_migrations (version) VALUES ('20101130085559');

INSERT INTO schema_migrations (version) VALUES ('20101214120239');

INSERT INTO schema_migrations (version) VALUES ('20101214131809');

INSERT INTO schema_migrations (version) VALUES ('20101214134115');

INSERT INTO schema_migrations (version) VALUES ('20101215125928');

INSERT INTO schema_migrations (version) VALUES ('20101215143259');

INSERT INTO schema_migrations (version) VALUES ('20101216075651');

INSERT INTO schema_migrations (version) VALUES ('20101220085341');

INSERT INTO schema_migrations (version) VALUES ('20101220090023');

INSERT INTO schema_migrations (version) VALUES ('20101220093519');

INSERT INTO schema_migrations (version) VALUES ('20101220095343');

INSERT INTO schema_migrations (version) VALUES ('20101220103344');

INSERT INTO schema_migrations (version) VALUES ('20101220125403');

INSERT INTO schema_migrations (version) VALUES ('20101220130622');

INSERT INTO schema_migrations (version) VALUES ('20101220132202');

INSERT INTO schema_migrations (version) VALUES ('20101220132535');

INSERT INTO schema_migrations (version) VALUES ('20101220134256');

INSERT INTO schema_migrations (version) VALUES ('20101220134755');

INSERT INTO schema_migrations (version) VALUES ('20101220135406');

INSERT INTO schema_migrations (version) VALUES ('20101220140959');

INSERT INTO schema_migrations (version) VALUES ('20101220144657');

INSERT INTO schema_migrations (version) VALUES ('20101221103025');

INSERT INTO schema_migrations (version) VALUES ('20101221135030');

INSERT INTO schema_migrations (version) VALUES ('20101223145634');

INSERT INTO schema_migrations (version) VALUES ('20101228124739');

INSERT INTO schema_migrations (version) VALUES ('20101228130141');

INSERT INTO schema_migrations (version) VALUES ('20101228130559');

INSERT INTO schema_migrations (version) VALUES ('20101228135229');

INSERT INTO schema_migrations (version) VALUES ('20101228135541');

INSERT INTO schema_migrations (version) VALUES ('20101228150220');

INSERT INTO schema_migrations (version) VALUES ('20101228151439');

INSERT INTO schema_migrations (version) VALUES ('20101229100627');

INSERT INTO schema_migrations (version) VALUES ('20110103130627');

INSERT INTO schema_migrations (version) VALUES ('20110103131448');

INSERT INTO schema_migrations (version) VALUES ('20110103133441');

INSERT INTO schema_migrations (version) VALUES ('20110103142341');

INSERT INTO schema_migrations (version) VALUES ('20110103153636');

INSERT INTO schema_migrations (version) VALUES ('20110103154777');

INSERT INTO schema_migrations (version) VALUES ('20110104152319');

INSERT INTO schema_migrations (version) VALUES ('20110105124901');

INSERT INTO schema_migrations (version) VALUES ('20110106153619');

INSERT INTO schema_migrations (version) VALUES ('20110110123150');

INSERT INTO schema_migrations (version) VALUES ('20110111102439');

INSERT INTO schema_migrations (version) VALUES ('20110111113032');

INSERT INTO schema_migrations (version) VALUES ('20110111123438');

INSERT INTO schema_migrations (version) VALUES ('20110111124726');

INSERT INTO schema_migrations (version) VALUES ('20110117094956');

INSERT INTO schema_migrations (version) VALUES ('20110124084603');

INSERT INTO schema_migrations (version) VALUES ('20110124094105');

INSERT INTO schema_migrations (version) VALUES ('20110124122629');

INSERT INTO schema_migrations (version) VALUES ('20110124133234');

INSERT INTO schema_migrations (version) VALUES ('20110125133819');

INSERT INTO schema_migrations (version) VALUES ('20110125134450');

INSERT INTO schema_migrations (version) VALUES ('20110125140523');

INSERT INTO schema_migrations (version) VALUES ('20110125143151');

INSERT INTO schema_migrations (version) VALUES ('20110202094221');

INSERT INTO schema_migrations (version) VALUES ('20110204100335');

INSERT INTO schema_migrations (version) VALUES ('20110204131827');

INSERT INTO schema_migrations (version) VALUES ('20110208153030');

INSERT INTO schema_migrations (version) VALUES ('20110209152155');

INSERT INTO schema_migrations (version) VALUES ('20110216142933');

INSERT INTO schema_migrations (version) VALUES ('20110218060430');

INSERT INTO schema_migrations (version) VALUES ('20110218082903');

INSERT INTO schema_migrations (version) VALUES ('20110218085536');

INSERT INTO schema_migrations (version) VALUES ('20110218121909');

INSERT INTO schema_migrations (version) VALUES ('20110221031110');

INSERT INTO schema_migrations (version) VALUES ('20110221084217');

INSERT INTO schema_migrations (version) VALUES ('20110222000411');

INSERT INTO schema_migrations (version) VALUES ('20110222145248');

INSERT INTO schema_migrations (version) VALUES ('20110223092514');

INSERT INTO schema_migrations (version) VALUES ('20110224120440');

INSERT INTO schema_migrations (version) VALUES ('20110224120833');

INSERT INTO schema_migrations (version) VALUES ('20110228091731');

INSERT INTO schema_migrations (version) VALUES ('20110228091925');

INSERT INTO schema_migrations (version) VALUES ('20110301094435');

INSERT INTO schema_migrations (version) VALUES ('20110301111418');

INSERT INTO schema_migrations (version) VALUES ('20110302061947');

INSERT INTO schema_migrations (version) VALUES ('20110302065818');

INSERT INTO schema_migrations (version) VALUES ('20110302071553');

INSERT INTO schema_migrations (version) VALUES ('20110303035051');

INSERT INTO schema_migrations (version) VALUES ('20110303131302');

INSERT INTO schema_migrations (version) VALUES ('20110303133343');

INSERT INTO schema_migrations (version) VALUES ('20110303163453');

INSERT INTO schema_migrations (version) VALUES ('20110314031419');

INSERT INTO schema_migrations (version) VALUES ('20110314135742');

INSERT INTO schema_migrations (version) VALUES ('20110315130753');

INSERT INTO schema_migrations (version) VALUES ('20110316071728');

INSERT INTO schema_migrations (version) VALUES ('20110321152142');

INSERT INTO schema_migrations (version) VALUES ('20110323123331');

INSERT INTO schema_migrations (version) VALUES ('20110323130110');

INSERT INTO schema_migrations (version) VALUES ('20110324070727');

INSERT INTO schema_migrations (version) VALUES ('20110328082812');

INSERT INTO schema_migrations (version) VALUES ('20110329123742');

INSERT INTO schema_migrations (version) VALUES ('20110329135544');

INSERT INTO schema_migrations (version) VALUES ('20110330132155');

INSERT INTO schema_migrations (version) VALUES ('20110404094122');

INSERT INTO schema_migrations (version) VALUES ('20110411092200');

INSERT INTO schema_migrations (version) VALUES ('20110412060101');

INSERT INTO schema_migrations (version) VALUES ('20110426154026');

INSERT INTO schema_migrations (version) VALUES ('20110502080548');

INSERT INTO schema_migrations (version) VALUES ('20110503064024');

INSERT INTO schema_migrations (version) VALUES ('20110503162827');

INSERT INTO schema_migrations (version) VALUES ('20110504114544');

INSERT INTO schema_migrations (version) VALUES ('20110505095551');

INSERT INTO schema_migrations (version) VALUES ('20110511084803');

INSERT INTO schema_migrations (version) VALUES ('20110511121746');

INSERT INTO schema_migrations (version) VALUES ('20110512122812');

INSERT INTO schema_migrations (version) VALUES ('20110516114922');

INSERT INTO schema_migrations (version) VALUES ('20110516134408');

INSERT INTO schema_migrations (version) VALUES ('20110517093002');

INSERT INTO schema_migrations (version) VALUES ('20110523095712');

INSERT INTO schema_migrations (version) VALUES ('20110523124449');

INSERT INTO schema_migrations (version) VALUES ('20110525135156');

INSERT INTO schema_migrations (version) VALUES ('20110525151803');

INSERT INTO schema_migrations (version) VALUES ('20110527152051');

INSERT INTO schema_migrations (version) VALUES ('20110615092602');

INSERT INTO schema_migrations (version) VALUES ('20110616123451');

INSERT INTO schema_migrations (version) VALUES ('20110616125125');

INSERT INTO schema_migrations (version) VALUES ('20110616135332');

INSERT INTO schema_migrations (version) VALUES ('20110620121432');

INSERT INTO schema_migrations (version) VALUES ('20110623102111');

INSERT INTO schema_migrations (version) VALUES ('20110623122158');

INSERT INTO schema_migrations (version) VALUES ('20110623151304');

INSERT INTO schema_migrations (version) VALUES ('20110704154453');

INSERT INTO schema_migrations (version) VALUES ('20110707043107');

INSERT INTO schema_migrations (version) VALUES ('20110707054537');

INSERT INTO schema_migrations (version) VALUES ('20110707094829');

INSERT INTO schema_migrations (version) VALUES ('20110707133607');

INSERT INTO schema_migrations (version) VALUES ('20110707133608');

INSERT INTO schema_migrations (version) VALUES ('20110708040526');

INSERT INTO schema_migrations (version) VALUES ('20110708043815');

INSERT INTO schema_migrations (version) VALUES ('20110711062043');

INSERT INTO schema_migrations (version) VALUES ('20110711064615');

INSERT INTO schema_migrations (version) VALUES ('20110711072246');

INSERT INTO schema_migrations (version) VALUES ('20110711075624');

INSERT INTO schema_migrations (version) VALUES ('20110711101614');

INSERT INTO schema_migrations (version) VALUES ('20110711113032');

INSERT INTO schema_migrations (version) VALUES ('20110711151538');

INSERT INTO schema_migrations (version) VALUES ('20110712042557');

INSERT INTO schema_migrations (version) VALUES ('20110714083016');

INSERT INTO schema_migrations (version) VALUES ('20110714095941');

INSERT INTO schema_migrations (version) VALUES ('20110714184907');

INSERT INTO schema_migrations (version) VALUES ('20110714194143');

INSERT INTO schema_migrations (version) VALUES ('20110715122053');

INSERT INTO schema_migrations (version) VALUES ('20110715134150');

INSERT INTO schema_migrations (version) VALUES ('20110721091318');

INSERT INTO schema_migrations (version) VALUES ('20110722060845');

INSERT INTO schema_migrations (version) VALUES ('20110722070900');

INSERT INTO schema_migrations (version) VALUES ('20110727142657');

INSERT INTO schema_migrations (version) VALUES ('20110727145558');

INSERT INTO schema_migrations (version) VALUES ('20110728094208');

INSERT INTO schema_migrations (version) VALUES ('20110728094209');

INSERT INTO schema_migrations (version) VALUES ('20110728094210');

INSERT INTO schema_migrations (version) VALUES ('20110817112020');

INSERT INTO schema_migrations (version) VALUES ('20110817122008');

INSERT INTO schema_migrations (version) VALUES ('20110818103609');

INSERT INTO schema_migrations (version) VALUES ('20110823091054');

INSERT INTO schema_migrations (version) VALUES ('20110824032701');

INSERT INTO schema_migrations (version) VALUES ('20110824033241');

INSERT INTO schema_migrations (version) VALUES ('20110824033613');

INSERT INTO schema_migrations (version) VALUES ('20110824043703');

INSERT INTO schema_migrations (version) VALUES ('20110824060824');

INSERT INTO schema_migrations (version) VALUES ('20110824072123');

INSERT INTO schema_migrations (version) VALUES ('20110824072824');

INSERT INTO schema_migrations (version) VALUES ('20110824074331');

INSERT INTO schema_migrations (version) VALUES ('20110824082429');

INSERT INTO schema_migrations (version) VALUES ('20110825075516');

INSERT INTO schema_migrations (version) VALUES ('20110825083111');

INSERT INTO schema_migrations (version) VALUES ('20110825084427');

INSERT INTO schema_migrations (version) VALUES ('20110901150853');

INSERT INTO schema_migrations (version) VALUES ('20110902075847');

INSERT INTO schema_migrations (version) VALUES ('20110907124327');

INSERT INTO schema_migrations (version) VALUES ('20110908090211');

INSERT INTO schema_migrations (version) VALUES ('20110909143128');

INSERT INTO schema_migrations (version) VALUES ('20110914144453');

INSERT INTO schema_migrations (version) VALUES ('20110921072546');

INSERT INTO schema_migrations (version) VALUES ('20110921080327');

INSERT INTO schema_migrations (version) VALUES ('20110922143054');

INSERT INTO schema_migrations (version) VALUES ('20110929140244');

INSERT INTO schema_migrations (version) VALUES ('20110929143616');

INSERT INTO schema_migrations (version) VALUES ('20111003073845');

INSERT INTO schema_migrations (version) VALUES ('20111010123150');

INSERT INTO schema_migrations (version) VALUES ('20111018114137');

INSERT INTO schema_migrations (version) VALUES ('20111018115216');

INSERT INTO schema_migrations (version) VALUES ('20111020153313');

INSERT INTO schema_migrations (version) VALUES ('20111027134857');

INSERT INTO schema_migrations (version) VALUES ('20111031091620');

INSERT INTO schema_migrations (version) VALUES ('20111102095022');

INSERT INTO schema_migrations (version) VALUES ('20111107082350');

INSERT INTO schema_migrations (version) VALUES ('20111109105129');

INSERT INTO schema_migrations (version) VALUES ('20111118105304');

INSERT INTO schema_migrations (version) VALUES ('20111124155441');

INSERT INTO schema_migrations (version) VALUES ('20111206100559');

INSERT INTO schema_migrations (version) VALUES ('20111220093224');

INSERT INTO schema_migrations (version) VALUES ('20120106055413');