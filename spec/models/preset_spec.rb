require 'spec_helper'

describe Preset, :etsource_fixture do
  it "initializes" do
    preset = Preset.new(id: 1, user_values: {}, end_year: 2050, area_code: 'nl', foo_bar: 'has no effect')
    preset.id.should          == 1
    preset.user_values.should == {}
    preset.end_year.should    == 2050
    preset.area_code.should   == 'nl'
  end

  it "load records" do
    puts Preset.all.length
    Preset.all.map(&:id).include?(2999).should be_true
  end


  it "#to_scenario returns a scenario" do
    scenario = Preset.all.first.to_scenario
    scenario.class.should == Scenario
  end

end
