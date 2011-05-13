# == Schema Information
#
# Table name: slot_datas
#
#  id         :integer(4)      not null, primary key
#  dataset_id :integer(4)
#  slot_id    :integer(4)
#  conversion :float
#  dynamic    :boolean(1)
#

class SlotData < ActiveRecord::Base
  set_table_name "slot_datas"
  include DatasetTouchOnUpdate

  belongs_to :dataset
  belongs_to :slot

  def dataset_key
    Qernel::DatasetItem.compute_dataset_key(Qernel::Slot, slot_id)
  end

end

