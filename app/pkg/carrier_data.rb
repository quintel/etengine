class CarrierData < ActiveRecord::Base
  set_table_name "carrier_datas"
  include DatasetTouchOnUpdate

  has_paper_trail

  belongs_to :area
  belongs_to :carrier

  after_save :touch_dataset


  def datasets
    Dataset.find_all_by_area_id(area_id)
  end

  ##
  # CarrierData belongs to Area rather than Dataset.
  # Therefore we touch all Dataset objects of that Area.
  #
  def touch_dataset
    datasets.each(&:touch)
  end

  validates_uniqueness_of :carrier_id, :scope => :area_id, :on => :create, :message => "must be unique"

  def dataset_key
    Qernel::DatasetItem.compute_dataset_key(Qernel::Carrier, carrier_id)
  end
end


# == Schema Information
#
# Table name: carrier_datas
#
#  id                         :integer(4)      not null, primary key
#  created_at                 :datetime
#  updated_at                 :datetime
#  dataset_id              :integer(4)
#  carrier_id                 :integer(4)
#  cost_per_mj                :float
#  co2_per_mj                 :float
#  sustainable                :float
#  infinite                   :float
#  typical_production_per_km2 :float
#  area_id                    :integer(4)
#

