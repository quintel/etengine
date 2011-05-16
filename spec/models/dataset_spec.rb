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
