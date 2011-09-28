class RenameSqlStatementsForUnusedConverterMethodsInGqueries < ActiveRecord::Migration
  def self.up
    Gquery.all.each do |gquery|
      gquery.query.gsub!(/typical_capacity_gross_in_mj_s/,        "network_capacity_available_in_mw")
      gquery.query.gsub!(/typical_capacity_effective_in_mj_s/,    "network_capacity_used_in_mw")
      gquery.query.gsub!(/overnight_investment_ex_co2_per_mj_s/,  "network_expansion_costs_in_euro_per_mw")
      gquery.query.gsub!(/cost_om_fixed_per_mj/,                  "costs_per_mj")
      gquery.save
    end
  end

  def self.down
    Gquery.all.each do |gquery|
      gquery.query.gsub!(/network_capacity_available_in_mw/,        "typical_capacity_gross_in_mj_s")
      gquery.query.gsub!(/network_capacity_used_in_mw/,             "typical_capacity_effective_in_mj_s")
      gquery.query.gsub!(/network_expansion_costs_in_euro_per_mw/,  "overnight_investment_ex_co2_per_mj_s")
      gquery.query.gsub!(/costs_per_mj/,                            "cost_om_fixed_per_mj")
      gquery.save
    end
  end
end
