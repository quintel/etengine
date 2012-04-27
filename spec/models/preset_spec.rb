require 'spec_helper'

describe Preset do
  it "should initialize" do
    preset = Preset.new(id: 1, user_values: {}, end_year: 2050, area_code: 'nl', foo_bar: 'has no effect')
    preset.id.should          == 1
    preset.user_values.should == {}
    preset.end_year.should    == 2050
    preset.area_code.should   == 'nl'
  end

  it "should load_records" do
    Preset.all.map(&:id).include?(2999).should be_true
  end
end