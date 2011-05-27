require 'spec_helper'

describe Dataset::CarrierData do
  let!(:carrier_data) { Factory(:carrier_data) }
  it { should belong_to :area }
  it { should belong_to :carrier }
  it { should validate_uniqueness_of(:carrier_id).scoped_to(:area_id) }
end

