class MigratePurchasePricePerMwInputGrowthTotal < ActiveRecord::Migration
  def self.up
    Input.where(:attr_name => 'purchase_price_per_mw_input_growth_total').each do |input|
      keys = input.keys.split('_AND_').map(&:strip).compact.uniq.join(',')
      query = "UPDATE(V(#{keys}), purchase_price_per_mw_input, USER_INPUT())"

      input.v1_legacy_unit = '%'
      input.query = query
      input.save!
    end
  end

  def self.down
    Input.where(:attr_name => 'purchase_price_per_mw_input_growth_total').each do |input|
      input.v1_legacy_unit = nil
      input.query = nil
      input.save
    end
  end
end
