require 'spec_helper'

describe Dataset do
  it { should have_one :graph }
  it { should belong_to :blueprint }
  it { should belong_to :area }
  it { should have_many :converter_datas }
  it { should have_many :link_datas }
  it { should have_many :slot_datas }
  it { should have_many :time_curve_entries }
end

# == Schema Information
#
# Table name: datasets
#
#  id           :integer(4)      not null, primary key
#  blueprint_id :integer(4)
#  region_code  :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  area_id      :integer(4)
#

