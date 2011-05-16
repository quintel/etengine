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
      Dataset::CarrierData.should_receive(:create).with(any_args).exactly(Carrier.count).times
      @area.save
    end
  end
end



