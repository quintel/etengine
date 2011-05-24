require 'spec_helper'

describe Dataset::CarrierData do
  let!(:carrier_data) { Factory(:carrier_data) }
  it { should belong_to :area }
  it { should belong_to :carrier }
  it { should validate_uniqueness_of(:carrier_id).scoped_to(:area_id) }
end

# == Schema Information
#
# Table name: dataset_carrier_data
#
#  id                         :integer(4)      not null, primary key
#  created_at                 :datetime
#  updated_at                 :datetime
#  carrier_id                 :integer(4)
#  cost_per_mj                :float
#  co2_per_mj                 :float
#  sustainable                :float
#  typical_production_per_km2 :float
#  area_id                    :integer(4)
#  kg_per_liter               :float
#  mj_per_kg                  :float
#  co2_exploration_per_mj     :float           default(0.0)
#  co2_extraction_per_mj      :float           default(0.0)
#  co2_treatment_per_mj       :float           default(0.0)
#  co2_transportation_per_mj  :float           default(0.0)
#  co2_waste_treatment_per_mj :float           default(0.0)
#

