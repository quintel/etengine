require 'spec_helper'

describe Dataset::SlotData do
  it { should belong_to :dataset }
  it { should belong_to :slot }
end

# == Schema Information
#
# Table name: dataset_slot_data
#
#  id         :integer(4)      not null, primary key
#  dataset_id :integer(4)
#  slot_id    :integer(4)
#  conversion :float
#  dynamic    :boolean(1)
#

