require 'spec_helper'

describe Area do

  describe "#create" do
    before(:all) do
      load_carriers
    end

    before do
      @area = Area.new(:country => 'xz')
    end

    it "should create a CarrierData for every Carrier" do
   #   require 'ruby-debug'; debugger
      @area.save
      @area.carrier_datas.count.should == Carrier.count
    end
  end
end




