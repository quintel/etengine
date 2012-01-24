class RenameSqlStatementsForUnusedConverterMethodsInGqueries < ActiveRecord::Migration
  def self.up
    Gquery.all.each do |gquery|
      q = gquery.query
      q = q.gsub(/typical_capacity_gross_in_mj_s/,        "network_capacity_available_in_mw")
      q = q.gsub(/typical_capacity_effective_in_mj_s/,    "network_capacity_used_in_mw")
      q = q.gsub(/overnight_investment_ex_co2_per_mj_s/,  "network_expansion_costs_in_euro_per_mw")
      q = q.gsub(/cost_om_fixed_per_mj/,                  "costs_per_mj")
      gquery.query = q

      gquery.save
    end; nil
  end

  def self.down
    Gquery.all.each do |gquery|
      q = gquery.query
      q = q.gsub!(/network_capacity_available_in_mw/,        "typical_capacity_gross_in_mj_s")
      q = q.gsub!(/network_capacity_used_in_mw/,             "typical_capacity_effective_in_mj_s")
      q = q.gsub!(/network_expansion_costs_in_euro_per_mw/,  "overnight_investment_ex_co2_per_mj_s")
      q = q.gsub!(/costs_per_mj/,                            "cost_om_fixed_per_mj")
      gquery.query = q
      gquery.save
    end
  end
end
